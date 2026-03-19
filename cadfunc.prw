#include "totvs.ch"

/*/{Protheus.doc} u_cadFunc
    Rotina para cadastrar colaboradores no relogio ControlID a partir do Protheus.
    Integra com o endpoint /add_users.fcgi
    @author RSanthos
    @since 19/03/2026
/*/
user function cadFunc()
    local cUrl      := "https://192.168.0.129" // IP do relogio (ajustar conforme necessidade)
    local cSession  := ""
    local oRest     := FWRest():New(cUrl)
    local cBody     := ""
    local cResponse := ""
    local oUser     := Nil
    local aUsers    := {}
    
    // Simulação de dados vindo do Protheus (SRA - Funcionarios)
    // Em um cenário real, voce poderia passar o ID do funcionario como parametro
    local cNome     := "JOAO DA SILVA"
    local cCPF      := "12345678901"
    local cMatric   := "000123"
    local cPis      := "12345678901"
    
    // 1. Realizar Login para obter a sessao
    // JSON Enviado: {"login":"admin","password":"admin"}
    oRest:setPath("/login.fcgi")
    cBody := '{"login":"admin","password":"admin"}'
    oRest:setPostRequest(cBody)
    
    if oRest:Post()
        cResponse := oRest:getResult()
        cSession := extrairSession(cResponse)
    else
        conout("[ERROR] Falha no login: " + oRest:getLastError())
        MsgStop("Falha na comunicacao com o relogio (Login).", "Erro ControlID")
        return .F.
    endif

    if !empty(cSession)
        // 2. Montar o objeto do usuario para o ControlID
        // Nota: O ControlID espera um array de usuarios no campo "users"
        
        oUser := JsonObject():New()
        oUser["name"]         := cNome
        oUser["registration"] := val(cMatric)
        
        // Se estiver usando Portaria 671, o 'mode' na URL deve ser 671 e enviamos CPF
        // Se for legado, enviamos PIS
        oUser["cpf"]          := val(cCPF) 
        // oUser["pis"]       := val(cPis) // Use se nao for 671
        
        aadd(aUsers, oUser)
        
        // Criar o body principal
        oMainJson := JsonObject():New()
        oMainJson["users"] := aUsers
        
        cBody := oMainJson:ToJson()
        
        // JSON Enviado: {"users":[{"name":"JOAO DA SILVA","registration":123,"cpf":12345678901}]}
        // 3. Enviar para o relogio
        // Usando mode=671 conforme documentacao para suportar CPF
        oRest:setPath("/add_users.fcgi?session=" + cSession + "&mode=671")
        oRest:setPostRequest(cBody)
        
        conout("[INFO] Enviando cadastro: " + cBody)
        
        if oRest:Post()
            cResponse := oRest:getResult()
            conout("[INFO] Resposta do relogio: " + cResponse)
            MsgInfo("Colaborador " + cNome + " cadastrado com sucesso no relogio!", "Sucesso")
        else
            conout("[ERROR] Falha ao cadastrar usuario: " + oRest:getLastError())
            MsgStop("Erro ao enviar colaborador para o relogio.", "Erro ControlID")
        endif
    endif

return nil

/*/{Protheus.doc} extrairSession
    Extrai o token de sessao do JSON de retorno do login.
/*/
static function extrairSession(cJson)
    local oJson := nil
    local cSession := ""
    
    FWJsonDeserialize(cJson, @oJson)
    if oJson != nil .and. type("oJson:session") == "C"
        cSession := oJson:session
    endif
return cSession
