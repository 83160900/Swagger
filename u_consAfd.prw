#include "totvs.ch"

/*/{Protheus.doc} u_consAfd
    Exemplo de consumo do AFD (Arquivo de Fonte de Dados) do relogio ControlID via AdvPL.
    @author Junie
    @since 19/03/2026
/*/
user function consAfd()
    local cUrl      := "https://192.168.0.129" // IP do relogio
    local cSession  := ""
    local oRest     := FWRest():New(cUrl)
    local cBody     := ""
    local cResponse := ""
    
    // 1. Realizar Login para obter a sessao
    oRest:setPath("/login.fcgi")
    cBody := '{"login":"admin","password":"admin"}'
    oRest:setPostRequest(cBody)
    
    if oRest:Post()
        cResponse := oRest:getResult()
        // Aqui voce usaria uma funcao para extrair o campo "session" do JSON de retorno
        // Exemplo simplificado:
        cSession := extrairSession(cResponse)
    else
        conout("[ERROR] Falha no login: " + oRest:getLastError())
        return .F.
    endif

    if !empty(cSession)
        // 2. Solicitar o AFD (Exemplo: a partir de uma data ou NSR)
        oRest:setPath("/get_afd.fcgi?session=" + cSession + "&mode=671")
        
        // Exemplo: Buscar a partir de 18/03/2026
        cBody := '{"initial_date":{"day":18,"month":3,"year":2026}}'
        oRest:setPostRequest(cBody)
        
        if oRest:Post()
            cResponse := oRest:getResult()
            // cResponse agora contem o conteudo do arquivo AFD (texto plano)
            conout("[INFO] AFD recebido com sucesso!")
            
            // Aqui voce processaria o cResponse linha a linha para importar no Protheus
            processarAfd(cResponse)
        else
            conout("[ERROR] Falha ao obter AFD: " + oRest:getLastError())
        endif
    endif

return nil

static function extrairSession(cJson)
    local oJson := nil
    local cSession := ""
    
    FWJsonDeserialize(cJson, @oJson)
    if oJson != nil .and. type("oJson:session") == "C"
        cSession := oJson:session
    endif
return cSession

static function processarAfd(cAfd)
    local aLinhas := strTokArr(cAfd, chr(13)+chr(10))
    local nI
    
    for nI := 1 to len(aLinhas)
        // Lógica de importação para a tabela do Protheus (ex: SP8)
        conout("Linha AFD: " + aLinhas[nI])
    next
return nil
