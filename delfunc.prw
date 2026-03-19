#include "totvs.ch"

/*/{Protheus.doc} delfunc
    Rotina para deletar colaboradores no relogio ControlID a partir do Protheus (Rescisao).
    Integra com o endpoint /remove_users.fcgi
    @author RSanthos (Junie)
    @since 19/03/2026
/*/
user function delfunc()
    local cUrl      := "https://192.168.0.129" // IP do relogio (ajustar conforme necessidade)
    local cSession  := ""
    local oRest     := FWRest():New(cUrl)
    local cBody     := ""
    local cResponse := ""
    local aUsers    := {}
    
    // Simulação de dados vindo do Protheus (SRA - Funcionarios)
    // Em um cenário real, voce poderia passar o CPF do funcionario como parametro
    local cCPF      := "12345678901"
    local cNome     := "JOAO DA SILVA" // Apenas para log/exibicao
    
    // 1. Realizar Login para obter a sessao
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
        // 2. Montar a lista de CPFs para remover
        // O ControlID espera um array de inteiros no campo "users"
        aadd(aUsers, val(cCPF))
        
        oMainJson := JsonObject():New()
        oMainJson["users"] := aUsers
        
        cBody := oMainJson:ToJson()
        
        // 3. Enviar para o relogio
        // Usando mode=671 conforme documentacao para suportar CPF
        oRest:setPath("/remove_users.fcgi?session=" + cSession + "&mode=671")
        oRest:setPostRequest(cBody)
        
        conout("[INFO] Enviando exclusao para o CPF " + cCPF + ": " + cBody)
        
        if oRest:Post()
            cResponse := oRest:getResult()
            conout("[INFO] Resposta do relogio: " + cResponse)
            MsgInfo("Colaborador " + cNome + " (CPF: " + cCPF + ") removido com sucesso no relogio!", "Sucesso")
        else
            conout("[ERROR] Falha ao remover usuario: " + oRest:getLastError())
            MsgStop("Erro ao remover colaborador do relogio.", "Erro ControlID")
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
