/*---------------------------------------------------------------------------*\
  Sistema....: Cadastros - Importacao
  Programa...: cad702.p
  Objetivo...: Importacao de informacoes para a tabela cadloc
  Responsavel: Fabio Oliveira
  Data.......: 18/06/2019 - Sol.: 
\*---------------------------------------------------------------------------*/
ROUTINE-LEVEL ON ERROR UNDO, THROW.

{shared.w}.

if sh-empresa = ? or
   sh-empresa = 0 then do.
   find first cademp
        where cademp.empresa  > 0
          and cademp.unidade <> 0
        no-error.
   if avail cademp then
      sh-empresa = cademp.empresa.
end.

{bib00359.i}.
{tabletostr.i}.
{bib00163.i}.
{sgt502.i}.

def     shared var sh-param            as longchar.
def     shared var sh-retorno          as longchar.

      
def buffer tmp-xmla for tmp-xml.
def buffer tmp-xml-array-props for tmp-xml.
def buffer tmp-xml-prop for tmp-xml.

def var ws-id-fila                     as int.
def var ws-nome-arq                    as char.
def var ws-formato                     as char.
def var ws-tipo-ret                    as char init 'DADOS'.
def var ws-empresa                     like cadloc.empresa.
def var ws-ok                          as log.
def var ws-ret                         as char.
def var ws-chave-cooperate             as char                   no-undo.
def var ws-cont-aux                    as inte                   no-undo.
def var ws-encerrou-lotes              as logi                   no-undo.
def var ws-lote                        like cadp73.lote          no-undo.
def var ws-msg-aux                     as char                   no-undo.
def var ws-formato-sessao              as char                   no-undo.
def var ws-primeiro-registro           as logi                   no-undo.
def var ws-diretorio-temp              as char                   no-undo.
def var ws-arq-entrada                 as char                   no-undo.
def var ws-arq-saida                   as char                   no-undo.
def var ws-erro-email                  as char                   no-undo.
def var ws-email-background            as logi init yes          no-undo.
def var wa-assunto-email               as char                   no-undo.
def var ws-emails-debug-erros          as char                   no-undo.

def var ws-parametro                   as char                   no-undo.
def var ws-email-erros-servico-cadp708 as char  /*cfg200*/       no-undo.
def var ws-email-debug-servico-cadp708 as char  /*cfg200*/       no-undo.



def buffer cadp73b for cadp73.
      
def temp-table tmpPropriedade
   field empresa                       like cadloc.empresa
   field cgc-cpf                       like cadloc.cgc-cpf
   field local-fat                     like cadloc.local-fat
   field numeroPropTerceiro            as int
   field chaveERP                      as char
   field nomePropriedade               as char
   field latitude                      like cadp73.latitude
   field longitude                     like cadp73.longitude
   field areaTotal                     as dec
   field dataTermino                   as date init ? form '99/99/9999'
   field areaCulturavel                as dec
   field situacao                      as char
   field msg                           as char
   field unidMedArea                   as char
   field fatorConversaoUnidMedAarea    as dec   
   index tmpPropriedade-1
      empresa    
      cgc-cpf    
      local-fat  
      numeroPropTerceiro
   index tmpPropriedade-2
      chaveERP
   index tmpPropriedade-3
      situacao.

{int700.w}.
{int700.i
   &ignorarexecutarConsulta = *
   }.
{int700a.i}.
repeat
   on error undo, leave.

   ws-formato-sessao = session:numeric-format.
   session:numeric-format = 'american'.
   
   run leParametros.
   
   ws-diretorio-temp = getDiretorioTemp().
       
   run lerXMLRequisicaoTipo(
      sh-param,
      output ws-id-fila,
      output ws-formato,
      output ws-tipo-ret).
   
   ws-nome-arq = nomeArqTemp(ws-id-fila).
   find first tmp-xml
        where tmp-xml.tag = 'parametros'
        no-error.

   if avail tmp-xml then
      find first tmp-xmla
           where tmp-xmla.id_pai = tmp-xml.id
             and tmp-xmla.tag    = 'dados'
           no-error.

   if not avail tmp-xmla then
      return.
   
   run criaTmpPropriedade.
   
   run criaRegistros.
       
   output stream sjson to value(ws-nome-arq).
   run abrirObj(no).
   run addObj('dados', no).
   run addArray('registro', no).

   for each tmpPropriedade
      break by tmpPropriedade.empresa
            by tmpPropriedade.cgc-cpf
            by tmpPropriedade.local-fat
            by tmpPropriedade.numeroPropTerceiro.
      
      run abrirObj(not(first(tmpPropriedade.numeroPropTerceiro))).
      run addProperty('chaveERP',tmpPropriedade.chaveERP, no).
      run addProperty('status', tmpPropriedade.situacao, yes).
      if tmpPropriedade.msg <> '' then
         run addProperty('msg', tmpPropriedade.msg, yes).
         
      run fecharObj.
   end.   
   
   run fecharArray.
   run fecharObj.
   run fecharObj.

   output stream sjson close.

   run tratarRetornoJson(
      ws-tipo-ret,
      ws-nome-arq,
      output sh-retorno
   ).
   
   release tmpPropriedade.
   find first tmpPropriedade use-index tmpPropriedade-1
        where tmpPropriedade.situacao = 'Erro'
        no-error.

   if(avail tmpPropriedade                   and
      ws-email-erros-servico-cadp708 <> '' ) or 
      ws-email-debug-servico-cadp708 <> ''   then do.
      
      ws-emails-debug-erros
         = ws-email-erros-servico-cadp708
         + ';'
         + ws-email-debug-servico-cadp708.
         
      find first cademp
           where cademp.empresa = sh-empresa
           no-error.
           
      ws-arq-entrada 
         = ws-diretorio-temp 
         + userid(ldbname(1))
         + 'arq_entrada.xml'.

      ws-arq-saida   
         = ws-diretorio-temp 
         + userid(ldbname(1))
         + 'arq_saida.json'.  
      
      wa-assunto-email
         = 'Erro/Debug servico de importacao (latitude)'.

      if avail cademp then
         wa-assunto-email
         = wa-assunto-email
         + cademp.sigla.
         
      if search(ws-arq-entrada) <> ? then
         os-delete silente value(ws-arq-entrada).
         
      if search(ws-arq-saida) <> ? then
         os-delete silente value(ws-arq-saida).
         
      output to value(ws-arq-entrada).
         export sh-param.
      output close.

      output to value(ws-arq-saida).
         export sh-retorno.
      output close.
         
      run sgt599c.p (getEnderecoServidorDeEMail()                  ,
                     getContaRemetenteDeEMail()                    ,
                     ws-emails-debug-erros                         , 
                     wa-assunto-email                              ,
                     'Erro/Debug de importacao servico (cadp708) ' ,
                     ws-arq-entrada + ',' + ws-arq-saida           ,
                     ws-email-background                           ,
                     output ws-erro-email).
                        
      os-delete silent value(ws-arq-entrada).
      os-delete silent value(ws-arq-saida).
   end.
      
   session:numeric-format = ws-formato-sessao.
   return.
end.




procedure separaChaveCooperate.
b-1:
repeat
   on error undo, throw.
   
   if(num-entries(tmpPropriedade.chaveERP, '#')) < 2 then do.
      assign
         tmpPropriedade.situacao = 'Erro'
         tmpPropriedade.msg      = 'ChaveERP incorreta.'.
   end.
   else if(num-entries(tmpPropriedade.chaveERP,'#') = 3) then do.
      tmpPropriedade.empresa   = sh-empresa.
      tmpPropriedade.cgc-cpf   = entry(1, tmpPropriedade.chaveERP,'#').
      tmpPropriedade.local-fat = int(entry(2, tmpPropriedade.chaveERP,'#')).
      tmpPropriedade.numeroPropTerceiro 
         = int(entry(3,tmpPropriedade.chaveERP,'#')).
   end.
   else do.
      tmpPropriedade.empresa   = int(entry(1,tmpPropriedade.chaveERP, '#')).
      tmpPropriedade.cgc-cpf   = entry(2,tmpPropriedade.chaveERP, '#').
      tmpPropriedade.local-fat = int(entry(3,tmpPropriedade.chaveERP, '#')).
      tmpPropriedade.numeroPropTerceiro
         = int(entry(4,tmpPropriedade.chaveERP,'#')).
   end.

   return 'separaChaveCooperate_ok'.
end.
catch eAnyError as progress.lang.error:
   return '|Procedure separaChaveCooperate => ' + 
          eAnyError:GetMessage(1).
end catch.
End Procedure.


procedure criaRegistros.
def var ws-cria-cadp08       as logi                   no-undo.
b-1:
repeat
   on error undo b-1, leave b-1.

   for each tmpPropriedade use-index tmpPropriedade-1
      where tmpPropriedade.situacao <> 'Erro'
      break by tmpPropriedade.empresa
            by tmpPropriedade.cgc-cpf
            by tmpPropriedade.local-fat
      on error undo, next.
      
      ws-msg-aux 
         = 'Procedure criaRegistros => '.
      
      find first cadloc
           where cadloc.empresa   = tmpPropriedade.empresa
             and cadloc.cgc-cpf   = tmpPropriedade.cgc-cpf
             and cadloc.local-fat = tmpPropriedade.local-fat
           no-error.
      
      if not avail cadloc then
         find first cadloc
              where cadloc.empresa       = tmpPropriedade.empresa
                and cadloc.cgc-cpf-local = tmpPropriedade.cgc-cpf
              no-error.
              
      if not avail cadloc then do.
         assign
            tmpPropriedade.situacao = 'Erro'
            tmpPropriedade.msg      = 'Local nao encontrado no Cooperate'.
         next.   
      end.      

      ws-primeiro-registro = no.
      
      if first-of(tmpPropriedade.local-fat) then
         ws-primeiro-registro = yes.
      
      run criaLotes.   /** Isolado por transacao **/
         
      if return-value <> 'criaLotes_ok' then do.
         assign
            tmpPropriedade.situacao = "Erro"
            tmpPropriedade.msg 
               = ws-msg-aux
               + ' - '
               + return-value.
         next.
      end.

      release cadp08.
   end.
   
   return 'criaRegistros_ok'.
end.
End Procedure.


procedure criaLotes.
def buffer cadp73c for cadp73.
def var ws-log-table as char.
b-1:
repeat trans
   on error undo, throw.
               
   ws-msg-aux 
      = ws-msg-aux
      + '|Procedure criaLotes => '.
      
      
   release cadp08.       
   find first cadp08 exclusive
        where cadp08.empresa     = cadloc.empresa
          and cadp08.cgc-cpf     = cadloc.cgc-cpf
          and cadp08.numero-prop = cadloc.local-fat 
        no-error 
        no-wait.
           
   if not avail cadp08 and
      locked    cadp08 then do.
      assign
         tmpPropriedade.situacao = "Erro"
         tmpPropriedade.msg 
            = ws-msg-aux
            + ' - '
            + error-status:get-message(1).
      next.
   end.
         
   if not avail cadp08 then do.
      create cadp08.
      assign
         cadp08.empresa          = cadloc.empresa
         cadp08.cgc-cpf          = cadloc.cgc-cpf
         cadp08.numero-propried  = cadloc.local-fat
         cadp08.nome-propr       = cadloc.nome
         cadp08.endereco         = cadloc.endereco
         cadp08.uf               = cadloc.uf.
   end.
      
   /** Encerra lotes criados pelo Cooperate **/
   if not new(cadp08)              and 
      ws-primeiro-registro   = yes then do.
      
      for each cadp73 no-lock
         where cadp73.empresa         = cadloc.empresa
           and cadp73.cgc-cpf         = cadloc.cgc-cpf
           and cadp73.numero-proprie  = cadloc.local-fat.
           
         if cadp73.id-terceiro = '' then do.
            find first cadp73c exclusive
                where recid(cadp73c) = recid(cadp73)
                no-error 
                no-wait.
      
            if not avail cadp73c and
               locked    cadp73c then do.
               return error-status:get-message(1).
            end.
            
            cadp73c.data-termino = today.
         end.   
         
         ws-encerrou-lotes = yes.   
         release cadp73.
         release cadp73c.
      end.
      
      assign
         cadp08.ha-agricultavel = 0
         cadp08.ha-terra        = 0.
      
   end.
   
   /*** Verifica/Cria lotes da propriedades ***/
   find first cadp73 exclusive
        where cadp73.empresa     = cadloc.empresa
          and cadp73.id-terceiro = string(tmpPropriedade.numeroPropTerce)
        no-error 
        no-wait.
        
   if not avail cadp73 and 
      locked    cadp73 then do.
      return error-status:get-message(1).
   end.
   
   if not avail cadp73 then do.
      ws-lote = 0.  
      find last cadp73b
          where cadp73b.empresa         = cadloc.empresa
            and cadp73b.cgc-cpf         = cadloc.cgc-cpf
            and cadp73b.numero-propried = cadloc.local-fat
          no-error.

      if avail cadp73b then
         ws-lote = cadp73b.lote.
          
      ws-lote = ws-lote + 1.      
      
      create cadp73.
      assign
         cadp73.empresa         = cadloc.empresa
         cadp73.cgc-cpf         = cadloc.cgc-cpf
         cadp73.numero-propried = cadloc.local-fat
         cadp73.lote            = ws-lote
         cadp73.id-terceiro     = string(tmpPropriedade.numeroPropTerce).
   end.

   ws-log-table = tableToStr(buffer tmpPropriedade:handle).

   assign
      cadp73.nome-propriedade = tmpPropriedade.nomePropriedade
      cadp73.latitude         = tmpPropriedade.latitude
      cadp73.longitude        = tmpPropriedade.longitude
      cadp73.data-termino     = tmpPropriedade.dataTermino
      cadp73.descricao        = cadp73.nome-propriedade
      cadp73.usuario          = userid(ldbname(1))
      cadp73.log-importacao   = ws-log-table
      cadp73.ha-total         = tmpPropriedade.areaTotal 
                              * tmpPropriedade.fatorConversaoUnidMedAarea
      cadp73.ha-agricultavel  = tmpPropriedade.areaCulturavel
                              * tmpPropriedade.fatorConversaoUnidMedAarea.
      
   if cadp73.data-termino = ?      or 
      cadp73.data-termino > today  then do.
      assign
         cadp08.ha-terra        
            = cadp08.ha-terra        
            + cadp73.ha-total
         cadp08.ha-agricultavel 
            = cadp08.ha-agricultavel 
            + cadp73.ha-agricultavel.
   end.   
   
   release cadp73.
   release cadp08.
   release cadp73b.
   
   tmpPropriedade.situacao = "OK".

   return 'criaLotes_ok'.
end.
catch eError as progress.lang.error:
   return eError:GetMessage(1).   
end catch.
End Procedure.


procedure criaTmpPropriedade.
b-1:
repeat
   on error undo, throw.

   ws-msg-aux 
      = 'Procedure criaTmpPropriedade => '.
      
   for each tmp-xml
      where tmp-xml.id_pai = tmp-xmla.id
        and tmp-xml.tag    = 'parceiro'.
      
      create tmpPropriedade.
      tmpPropriedade.chaveERP = findXMLbyID(tmp-xml.id, 'chaveERP').
             
      run separaChaveCooperate.
      if return-value <> 'separaChaveCooperate_ok' then do.
         assign
            tmpPropriedade.situacao = 'Erro'
            tmpPropriedade.msg   = 'chaveERP: '
                                 + tmpPropriedade.chaveERP
                                 + " "
                                 + ws-msg-aux
                                 + ' - ' 
                                 + return-value.
         next.                        
      end.
                                           
      run atribuiCamposTmpPropriedade.
      if return-value <> 'atribuiCamposTmpPropriedade_ok' then do.
         assign
            tmpPropriedade.situacao = "Erro"
            tmpPropriedade.msg      = ws-msg-aux
                                    + return-value.
      end.
   end.

   return 'criaTmpPropriedade_ok'.
end.
catch eAnyError as progress.lang.error:
   return eAnyError:GetMessage(1).
end catch.
End Procedure.


procedure atribuiCamposTmpPropriedade.
b-1:
repeat
   on error undo, throw.

   tmpPropriedade.nomePropri = findXMLbyID(tmp-xml.id,'nomePropriedade').
   tmpPropriedade.areaTotal  = dec(findXMLbyID(tmp-xml.id,'areaTotal')).
   tmpPropriedade.areaCultura= dec(findXMLbyID(tmp-xml.id,'areaCulturavel')).
   tmpPropriedade.dataTermino= date(findXMLbyID(tmp-xml.id,'dataTermino')).
   tmpPropriedade.latitude   = dec(findXMLbyID(tmp-xml.id,'latitude')).
   tmpPropriedade.longitude  = dec(findXMLbyID(tmp-xml.id,'longitude')).
   tmpPropriedade.unidMedArea= findXMLbyID(tmp-xml.id,'unidMedArea').
   tmpPropriedade.fatorConversaoUnidMedAarea 
                             = dec(findXMLbyID(tmp-xml.id,
                                   'fatorConversaoUnidMedArea')). 

   return 'atribuiCamposTmpPropriedade_ok'.
end.
catch objError AS Progress.Lang.Error:
    return '|Procedure atribuiCamposTmpPropriedade => ' +
           objError:getMessage(1).
end catch.
End Procedure.


procedure leParametros.
b-1:
do on error undo b-1, leave b-1.

   ws-parametro = 'param-email-erros-servico-cadp708'.
   ws-email-erros-servico-cadp708 = ''.

   run cfg50001.p(input 0, input 0, input ws-parametro,
                  input yes, input '', buffer cfg000).
   if avail cfg000 = yes then
      ws-email-erros-servico-cadp708 = cfg000.conteudo.
      
      
   ws-parametro = 'param-email-debug-servico-cadp708'.
   ws-email-debug-servico-cadp708 = ''.

   run cfg50001.p(input 0, input 0, input ws-parametro,
                  input yes, input '', buffer cfg000).
   if avail cfg000 = yes then
      ws-email-debug-servico-cadp708 = cfg000.conteudo.
   
   

   return 'leParametros_ok'.
end.
End Procedure.


