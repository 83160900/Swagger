#include "totvs.ch"

/*/{Protheus.doc} consAfd
    Exemplo de consumo do AFD (Arquivo de Fonte de Dados) do relogio ControlID via AdvPL.
    @author RSanthos
    @since 19/03/2026
/*/
user function consAfd()
    local cUrl      := "https://192.168.0.129" // IP do relogio
    local cSession  := ""
    local oRest     := FWRest():New(cUrl)
    local cBody     := ""
    local cResponse := ""
    
    // 1. Realizar Login para obter a sessao
    // JSON Enviado: {"login":"admin","password":"admin"}
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
        
        // JSON Enviado: {"initial_date":{"day":18,"month":3,"year":2026}}
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
    local cLinha := ""
    local cTipo := ""
    local cCNPJ := ""
    local cSerie := ""
    local oMainJson := JsonObject():New()
    local aMarcac   := {}
    local oMarcac   := nil
    local cData := ""
    local cHora := ""
    
    // 1. Identificar o cabeçalho (Tipo 1) para pegar CNPJ e Série do REP
    for nI := 1 to len(aLinhas)
        cLinha := aLinhas[nI]
        if len(cLinha) >= 11
            cTipo := substr(cLinha, 11, 1)
            if cTipo == "1"
                cCNPJ  := substr(cLinha, 12, 14) // CNPJ da Empresa
                cSerie := substr(cLinha, 187, 17) // Número de Série do REP
                exit
            endif
        endif
    next

    // 2. Processar as marcações (Tipo 3)
    for nI := 1 to len(aLinhas)
        cLinha := aLinhas[nI]
        if len(cLinha) >= 11
            cTipo := substr(cLinha, 11, 1)
            
            if cTipo == "3"
                oMarcac := JsonObject():New()
                
                // Formatação de Data: DDMMYYYY -> YYYY-MM-DD
                cData := substr(cLinha, 12, 8)
                cData := substr(cData, 5, 4) + "-" + substr(cData, 3, 2) + "-" + substr(cData, 1, 2)
                
                // Formatação de Hora: HHMM -> HH:MM
                cHora := substr(cLinha, 20, 4)
                cHora := substr(cHora, 1, 2) + ":" + substr(cHora, 3, 2)

                oMarcac["codRelogioExtChave"] := " " 
                oMarcac["codNsr"]             := val(substr(cLinha, 1, 10)) 
                oMarcac["codPisMsa"]          := substr(cLinha, 24, 12) 
                oMarcac["datMarcacAces"]      := cData
                oMarcac["numHorarMarcacAces"] := cHora
                oMarcac["codRep"]             := cSerie
                oMarcac["codUnidExtChave"]    := "T1D MG 01" // Empresa + Filial concatenada
                oMarcac["codUsuarExtChave"]   := "T1D MG 01 003651" // Empresa + Filial + Matricula (Exemplo Fixo)
                oMarcac["numVersLayout"]      := val(cTipo) 
                oMarcac["inscrEmp"]           := cCNPJ

                aadd(aMarcac, oMarcac)
            endif
        endif
    next
    
    oMainJson["marcas"] := aMarcac
    
    conout("[DEBUG] JSON Gerado para MSA_CONTROL_MARCAC:")
    conout(oMainJson:ToJson())

return oMainJson:ToJson()
