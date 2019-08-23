&GLOBAL Versao_ecd501_p 2019.07.18
&if defined(RetornarVersao_ecd501_p) = 0 &then
/*
   Obs: Evitar de utilizar o formato abaixo. 
        Pois se na rotina chamada o ultimo find nao for bem sucedido a rotina 
        retorna "error-status:error = yes" mesmo com a instrucao no-error. 
        E em alguns casos e inexistencia do registro nao deve cancelar o
        processo.
   run efd501b0.p no-error.
   if error-status:error then
*/
/*---------------------------------------------------------------------------*\
|*                   D A T A C O P E R     S O F T W A R E                   *|
\*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*\
  Sistema....: 08 - Contabilidade Geral
  Subsistema.: 02 - Livros Fiscais
  Programa...: ecd501.p
  Objetivo...: ECD - Geracao de arquivo mensal (Sped Contabil)
  Responsavel: Alysson Cervantes/Ronye
  Data.......: 20/01/2009 - Solicitacao: 66348
\*---------------------------------------------------------------------------*/

{ver500aa.i &Arquivo = cfg200a4 &Extensao = p   &VersaoBase = 2019.05.14}.
{ver500aa.i &Arquivo = cfg200bd &Extensao = p   &VersaoBase = 2019.03.18}.
{ver500aa.i &Arquivo = ctb516d  &Extensao = p   &VersaoBase = 2019.05.22}.
{ver500aa.i &Arquivo = ctb516f  &Extensao = p   &VersaoBase = 2019.05.22}.
{ver500aa.i &Arquivo = ctb530   &Extensao = p   &VersaoBase = 2019.05.20}.
{ver500aa.i &Arquivo = ctb543   &Extensao = p   &VersaoBase = 2019.05.20}.
{ver500aa.i &Arquivo = dre203   &Extensao = p   &VersaoBase = 2019.03.27}.
{ver500aa.i &Arquivo = ecd501   &Extensao = i   &VersaoBase = 2019.05.29}.
{ver500aa.i &Arquivo = ecd501   &Extensao = w   &VersaoBase = 2019.05.29}.
{ver500aa.i &Arquivo = ecd501a  &Extensao = i   &VersaoBase = 2019.01.29}.
{ver500aa.i &Arquivo = ecd501a  &Extensao = p   &VersaoBase = 2019.05.29}.
{ver500aa.i &Arquivo = ecd501b  &Extensao = p   &VersaoBase = 2019.01.29}.
{ver500aa.i &Arquivo = ecd501c  &Extensao = p   &VersaoBase = 2019.05.29}.
{ver500aa.i &Arquivo = fho500ai &Extensao = p   &VersaoBase = 2014.06.18}.
{ver500aa.i &Arquivo = fho200ai &Extensao = p   &VersaoBase = 2014.06.18}.
{ver500aa.i &Arquivo = log005cr &Extensao = trg &VersaoBase = 2019.05.22}.
{ver500aa.i &Arquivo = msg999dc &Extensao = i   &VersaoBase = 2019.05.29}.

{shared.i}.
{msg999dc.i
   &idecademp0 = *
   &idecademp  = *
   &idecadloc  = *
   &idetxt002  = *
   &MostraMensagemA = *
   &MostraMensagemB = *   
   &MostraMensagemC = *
   &ListaDeUnidades = *
   }. 
{bib00142.i}. /* EhAmbienteCertificacao() | EhAmbienteFabricaSoftware()  */
{device.w}.
{cademp91.w 
   &shared = "new shared"}.
{ecd501.w  
   &shared = "new shared"
   &CarregaTMPI030 = *
   }.
{ecd501a.i  
   &CodigoAglutinacaoDre002 = *
   }.
{ecd501.i
   &CarregaTMPI350 = *
   &exportaECD     = *
   }.
{bib00152.i}. /* getProcedureReturnOK(x) */
{bib00105.i}. /* opcao(x) */
{choose.w &file = tt-Arquivo &z =  tt-Arquivo}.
{utl511ls.i new}.
{bib00435.i}. /* solic=164384; get-lote-ctb-encerra-exerc(empresa,unidade) */

{choose.w &file = ctb001 &z = ctb001}.

DEFINE RECTANGLE rect_LinhaHorizontal1
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL 
     &IF '{&WINDOW-SYSTEM}' = 'TTY':U &THEN SIZE 78 BY 1
     &ELSE SIZE 78 BY 1 &ENDIF.

DEFINE RECTANGLE rect_LinhaHorizontal2
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL 
     &IF '{&WINDOW-SYSTEM}' = 'TTY':U &THEN SIZE 78 BY 1
     &ELSE SIZE 78 BY 1 &ENDIF.
     
DEFINE RECTANGLE rect_LinhaHorizontal3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL 
     &IF '{&WINDOW-SYSTEM}' = 'TTY':U &THEN SIZE 78 BY 1
     &ELSE SIZE 78 BY 1 &ENDIF.

def var v_seletorContabilidade   as char form 'x(16)'
                                 Extent  2 Init  ["  Centralizada  ",
                                                  " Descentralizada"].

def var v_SeletorTipoEncerramento as char  form 'x(10)'
                                  Extent 3 Init ["Trimestral",
                                                 " Semestral",
                                                 "   Anual  "].

def var r-cadpgn                     as rec no-undo.

def var v_mes-inicial                as int form '99' init 01.
def var v_mes-final                  as int form '99' init 12.
def var v_exercicio                  as int.
def var v_LinhaImport                AS CHA NO-UNDO.
def var v_Opcao                      as cha no-undo.
def var ws-demonstrativos            as log form 'Sim/Nao'  no-undo.
def var i                            as int.
def var y                            as char.

DEF STREAM s1.

def var ws-ide-filtro                as cha.

def frame t1
   ws-unidade
   cademp.sigla
      no-label                            
      form 'x(17)'
   v-data-constituicao 
      label 'Data Ato Constituicao' 
      form '99/99/9999'
      at 43
      skip
   v_mes-inicial
      label 'Mes Inicial.....'
      validate ((v_mes-inicial >= 1 and
                 v_mes-inicial <= 12),'mes invalido')
   v-data-conversao
      label 'Data ato Conversao...' 
      form '99/99/9999'
      at 43
      skip           
   v_mes-final   
      label 'Mes Final.......'
      validate((v_mes-final  >= 1  and
                v_mes-final  <= 12 and
                v_mes-final  >= v_mes-inicial),'mes invalido')
   v-num-livro
      label 'Numero do Livro......' 
      at 43
      skip           
   v_exercicio
      Label 'Ano Referencia..'
      form '9999'
      space (20)
   ws-oculta-lctos-estorno
      validate (ws-oculta-lctos-estorno ne ?, 'Informe Sim ou Nao')
      help 'Informe se o sistema deve ocultar os lancamentos de estorno'
      label 'Oculta Estorno.......'
     skip
   v_Encerramento
      label 'Faz Encerramento'
      Help 'A Empresa utiliza rotinas de encerramento do exercicio?'
   v_LoteEncerramento 
      label 'Lote Do Encerramento.' 
      at 43
      skip             
   ws-nome-arq
      label 'Nome Arquivo....'
      view-as fill-in size 56 by 1
      format 'x(256)'
   ws-demonstrativos
      Label 'Demonstrativos..'
      help 'Informa Demonstrativos Contabeis (J100/J150/J800) ?'
      skip
   ws-ind-sit-ini-per          form "9"
      Label 'Ind.Ini.Periodo.' 
      help 'Indicador de inicio de periodo.'
      skip
   ws-ind-fin-esc              form "9"
      Label 'Ind.Fin.Escricao' 
      help "Indicador de finalidade da escrituracao."
      skip
   ws-num-retif                form "9"
      Label 'Num.Retificacao.'
      help "Numero de retificacao."
      skip
   ws-dt-ex-social
      Label 'Data Enc.Ex.Soc.'
      form '99/99/9999'
      help "Data de encerramento do Exercicio Social."
      skip
   with 1 down row 5 centered overlay side-labels width 78
        title 'EXPORTACAO DE ARQUIVO DO SPED CONTABIL - ECD'.

def frame t1b 
   v_Exportar-Dre 
      label 'Exportar D.R.E....'
      form 'Sim/Nao'
      help 'Exportar DRE <S>-SIM <N>-NAO'
   ws-plano-dre
      label 'Plano Contas ...'
      help 'Plano de Contas DRE'
   dre001.descricao 
      no-label
      form 'x(20)' 
      skip
   ws-consolidado
      label 'D.R.E Consolidado.'
      skip
   v_Exportar-BP  
      label 'Exportar B.P......'
      form 'Sim/Nao'
      help 'Exportar Balanco Patrimonial <S>-SIM <N>-NAO'
   v_nivel-bp
      label 'Nivel B.P.......'
      form '99'
      help 'Informe o nivel do balanco Patrimonial'
      skip
   'Encerramento......:'
   v_seletortipoEncerramento 
      no-label
      skip
   ws-arq-rtf
      label 'Outras Inf. (J800)'
      skip 
   ws-exporta-DMPL
      label "Exporta DMPL......"
      form 'Sim/Nao'
      help "Exporta as demonstracoes das mutacoes do patrimonio   liquido"
      skip
   with 1 down row 13 centered overlay side-labels width 78
      title 'DEMONSTRATIVOS DO SPED CONTABIL - BLOCO J'.


def frame t2
   ws-unidade-descentralizada
      form '99'
      label 'Unidade...'
      help 'Informe a Unidade Matriz para escrituracao descentralizada'
   cademp.sigla
      no-label
   with 1 down row 11 col 58 overlay side-labels width 20 no-box.

def frame t3
   'Arquivo ECD'
      skip
   rect_LinhaHorizontal1
      skip
   ws-nome-arq 
      no-label
      form 'x(999)' 
      view-as fill-in size 78 by 1
   with 1 down row 11 overlay side-labels.

def frame t4
   v_ultimo-mes-demonstrativo
      form '99'
      label 'Mes.'
      help 'Informe o mes do ultimo encerramento dos demostrativos'
   with 1 down row 10 overlay centered side-labels
      title 'ULTIMO ENCERRAMENTO DEMONSTRATIVOS'.

def frame t5
   v_conta-encerramento-manual
      label 'Conta Encerramento'
      help 'Informe a conta contabil de encerramento manual'
   ctb001.descricao form 'x(40)'
      no-label
   with width 78 1 down row 10 overlay centered side-labels
      title 'CONTA PARA ENCERRAMENTO CONTABIL MANUAL'.

def frame t6a
   ws-cod-hash-sub
      help "Informacao do protocolo de entrega da declaracao original."   
      view-as fill-in size 40 by 1 
      form 'x(40)'
   with 1 down row 14 column 21 overlay no-labels width 42
      title 'PROTOCOLO ENTREGA DA DECL. ORIGINAL'.

def frame t6b
   ws-nire-subst
      help "NIRE da escrituracao que esta sendo substituida."
      view-as fill-in size 11 by 1 
      form "x(11)"
   with 1 down row 14 column 21 overlay no-labels width 13
      title 'NIRE SUBST.'.

form
   ws-ind-ini-v[1] form "x(58)" no-label skip
   ws-ind-ini-v[2] form "x(58)" no-label skip
   ws-ind-ini-v[3] form "x(58)" no-label skip
   ws-ind-ini-v[4] form "x(58)" no-label skip
   with frame ind-ini-periodo 1 down col 21 row 11 side-labels overlay
        title 'INDICADOR DO INICIO DO PERIODO'.

assign
   ws-ind-ini-v[1] = "0|Normal (inicio no primeiro dia do "
                   + "ano)" 
   ws-ind-ini-v[2] = "1|Abertura"
   ws-ind-ini-v[3] = "2|Result. cisao/fusao ou rem. de cisao/realizou"
                   + " incorp."
   ws-ind-ini-v[4] = "3|Ini. obrig. entrega da ECD no curso do ano"
                   + " calendario"
                   .
form
   ws-ind-fim-v[1] form "x(48)" no-label skip
   ws-ind-fim-v[2] form "x(48)" no-label skip
   with frame ind-fim-periodo 1 down col 21 row 12 side-labels overlay
        title 'INDICADOR DE FINALIDADE DA ESCRITURACAO'.

assign
   ws-ind-fim-v[1] = "0 - Original "
   ws-ind-fim-v[2] = "1 - Substituta "
   .

if sc-funcao = '' or
   sc-funcao = ?  then
   sc-funcao = ' ECD - GERACAO DE ARQUIVO MENSAL '.
      
MAIN:
repeat on error undo MAIN, leave MAIN:
   hide frame t1 no-pause.
   hide frame t2 no-pause.
   hide frame t3 no-pause.
   hide frame t4 no-pause.
   hide frame t5 no-pause.
   if keyfunc(lastkey) = 'end-error' then
      undo Main, leave MAIN.
      
   run GerarArquivoECD in this-procedure.

end.
hide frame t1 no-pause.
hide frame t1b no-pause.
hide frame f_mensagem no-pause.
put screen row 22 col 64 fill(' ',16).
return.


PROCEDURE GerarArquivoECD:
bloco-0:
repeat with  frame t1:
   clear frame t1.
   hide frame ind-ini-periodo no-pause.
   hide frame ind-fim-periodo no-pause.
   
   /* solic=164384; redmine http://projetos01.datacoper.com.br/issues/37594 */
   v_loteEncerramento = get-lote-ctb-encerra-exerc(sh-empresa,0).
   
   assign 
      v_exercicio            = year(sh-data) - 1
      ws-numeric-format      = session:numeric-format
      session:numeric-format = 'EUROPEAN'
      .

   run LimpaTemporarias in this-procedure no-error.
   pause 0. 
      
   put screen row 22 col 64 '(v: {&Versao_ecd501_p})'.
   {cademp01.up
      &unidade = ws-unidade
      &field   = "cademp.sigla"
      &go-on   = "recall"
      &help    = " <F7> Marca/Desmarca"
      }.
   put screen row 22 col 64 fill(' ',16).
   find first cademp
      where cademp.empresa = sh-empresa
        and cademp.unidade = ws-unidade
      no-error.
  
   sh-flg-ok = no.
   run VerificaParametros in this-procedure no-error.
   if sh-flg-ok = no then 
      do.
         sh-msg999-msg   
            = idecademp0(sh-empresa)
            + chr(10)
            + fill(' ',18)
            + 'Erro na procedure VerificaParametros'
            .
         run MostraMensagemA in this-procedure.
         undo bloco-0, return.
      end.
   assign
      sh-flg-ok = no
      ws-diretorio = ws-liv-dir-arqfiscais + '/'
      .
   
   for each cademps
      where cademps.marca = no.
      cademps.marca = yes.
   end.
 
   if keyfunc(lastkey) = 'recall' then 
      do.
         run cademp91 in this-procedure no-error.
         if keyfunc(lastkey) = 'end-error' then
            next.
      end.
   
   update v_mes-inicial.
   update v_mes-final.
   update v_exercicio.
   
   ws-ide-filtro
      = idecademp(sh-empresa,ws-unidade)
      + chr(10)
      + 'Periodo.........: '
      + string(v_mes-inicial)
      + '-'
      + string(v_mes-final)
      + '/'
      + string(v_exercicio)
      .
      
   assign 
      ws-data-ini = date(v_mes-inicial,01,v_exercicio) 
      ws-data-fin = date(v_mes-final,01,v_exercicio)
      ws-data-fin = date(v_mes-final,{lastday.i ws-data-fin},v_exercicio)
      .
   
   {periodo.i
      &dataInicial = ws-data-ini
      &dataFinal   = ws-data-fin
      &DEF_PERIODO = *
      }.
      
   do while true.
      update v-data-constituicao.
      
      if v_exercicio         < 2012 and
         v-data-constituicao = ? then 
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + 'Data Constituic.: ?'
               + chr(10)
               + fill(' ',18)
               + 'Data invalida.'
               .
            run MostraMensagemA in this-procedure.
            next.
         end.
      
      if year(v-data-constituicao) > v_exercicio then 
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + 'Data Constituic.: ?'
               + chr(10)
               + idetxt002(18,57,'',''
               + 'O ano da constituicao nao pode ser maior que o exercicio '
               + 'informado.')
               .
            run MostraMensagemA in this-procedure.
            next.
         end.
      else 
      if year(v-data-constituicao) = v_exercicio then
      if month(v-data-constituicao) > v_mes-inicial then 
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + 'Data Constituic.: ?'
               + chr(10)
               + idetxt002(18,57,'',''
               + 'O mes da constituicao nao pode ser maior que o mes '
               + 'inicial informado.')
               .
            run MostraMensagemA in this-procedure.
            next.
         end.
      leave.
   end.               
   
   do while true
      with frame t1.
      
      update v-data-conversao.
      if v_exercicio      < 2013                 and
        (v-data-conversao <= v-data-constituicao or
         v-data-conversao  = ?)                  then 
         do. 
            sh-msg999-msg   
               = idecademp0(sh-empresa)
               + chr(10)
               + fill(' ',18)
               + 'Data de conversao nao pode ser menor que ' 
               + string(v-data-constituicao)
               + "."
               . 
            run MostraMensagemA in this-procedure.
            undo, next.
      end.      

      if v-data-conversao <> ? then 
         do.
            if year(v-data-conversao) > v_exercicio then 
               do.
                  sh-msg999-msg
                     = ws-ide-filtro
                     + chr(10)
                     + 'Data Constituic.: ?'
                     + chr(10)
                     + idetxt002(18,57,'',''
                     + 'O ano da conversao nao pode ser maior que o exercicio '
                     + 'informado.')
                     .
                  run MostraMensagemA in this-procedure.
                  next.
               end.
            else 
            if year(v-data-conversao) = v_exercicio then
            if month(v-data-conversao) > v_mes-inicial then 
               do.
                  sh-msg999-msg
                     = ws-ide-filtro
                     + chr(10)
                     + 'Data Constituic.: ?'
                     + chr(10)
                     + idetxt002(18,57,'',''
                     + 'O mes da conversao nao pode ser maior que o mes '
                     + 'inicial informado.')
                     .
                  run MostraMensagemA in this-procedure.
                  next.
               end.
         end.   
      leave.
   end.  
   
   find first cadpgn 
      where cadpgn.empresa  = sh-empresa  
        and cadpgn.unidade  = 00
        and cadpgn.esp-dcto = 'ecd501'    
        and cadpgn.serie    = ' '        
      no-error.
   if not avail cadpgn then 
      do.
         create cadpgn.
         assign
            cadpgn.empresa   = sh-empresa
            cadpgn.unidade   = 00
            cadpgn.esp-dcto  = 'ecd501'
            cadpgn.serie     = ' '
            cadpgn.descricao ='livro diario'
            .
      end.
   
   v-num-livro = cadpgn.ult-livro + 1. 
   update v-num-livro.
   if cadpgn.ult-livro <> v-num-livro then 
      do.
         r-cadpgn = recid(cadpgn).
         find first cadpgn share
            where recid(cadpgn) = r-cadpgn 
            no-error.
         cadpgn.ult-livro = v-num-livro.
      end.   
   release cadpgn.
    
   update ws-oculta-lctos-estorno.
   
   do while true:
      v_Encerramento = yes.
      Update v_Encerramento.
   
      if v_Encerramento = no then
         if v_mes-final = 12             or
            v_mes-inicial <> v_mes-final then 
            do.
               sh-msg999-msg
                  = ws-ide-filtro
                  + chr(10)
                  + idetxt002(18,57,'',''
                  + 'ESTA OPCAO NAO IRA GERAR OS SALDOS DAS CONTAS DE '
                  + 'RESULTADO ANTES DO ENCERRAMENTO.'
                  + chr(10)
                  + 'REGISTROS I350-I355.')
                  .
               run MostraMensagemA in this-procedure.
            end.    
      disp v_LoteEncerramento.
      leave.
   end.
   
   assign 
      sh-cod-uni   = ws-unidade
      sh-dat-ini   = ws-data-ini
      sh-dat-fin   = ws-data-fin
      sh-num-retif = ws-num-retif
      ws-nome-arq  = ws-diretorio
                   + 'ECD-'
                   + caps(v_tipo-livro)
                   + trim(cademp.cgc)
                   + '-'
                   + string(month(ws-data-fin),'99')
                   + string(year(ws-data-ini),'9999') 
                   + '.txt'.
   

   if EhAmbienteFabricaSoftware() = yes and
      userid(ldbname(1)) = 'renato' then 
      ws-nome-arq = userid(ldbname(1)) + '.txt'.
      
   do while true.
      update ws-nome-arq.
      if ws-nome-arq = '' or
         ws-nome-arq = ?  then 
         do.
            sh-msg999-msg   
               = idecademp0(sh-empresa)
               + chr(10)
               + fill(' ',18)
               + 'Nome do arquivo deve ser informado!'
               .
            run MostraMensagemA in this-procedure.
            next.
         end.
      if search(ws-nome-arq) <> ? then 
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + 'Arquivo.........: '
               + ws-nome-arq
               + chr(10)
               + fill(' ',18)
               + 'O arquivo ja existe'
               .
            sh-msg999b-pergunta = 'Deseja sobrescrever? Sim/Nao?'.
            ws-msg999-respdef = no.
            run MostraMensagemB in this-procedure.
            if ws-msg999-respret = no then 
               next.
         end.
      leave.
   end.
   
   
   sh-nome-arquivo = ws-nome-arq.

   do while true.
      update ws-demonstrativos.
     
      v_tipo-encerramento = 'Anual'.
      if ws-demonstrativos = yes then
         bl-1:
         repeat 
            with  frame t1b.
         
            clear frame t1b.
            disp v_seletorTipoEncerramento.
            update v_Exportar-Dre.

            if v_Exportar-Dre then 
               do.
                  {dre00101.up
                     &plano       = ws-plano-dre
                     &field       = dre001.descricao
                     &form        = "with frame t1b"
                     &inc         = no
                     }.
                  if dre001.tip-plano = '3' then 
                     do.
                        sh-msg999-msg
                           = ws-ide-filtro
                           + chr(10)
                           + 'Data Constituic.: ?'
                           + chr(10)
                           + idetxt002(18,57,'',''
                           + 'Tipo do plano 3 - PIS/COFINS. '
                           + chr(10)
                           + 'Nao e possivel listar por esta rotina.')
                           .
                        run MostraMensagemA in this-procedure.
                        next.
                     end.
                  update ws-consolidado.
               end.
            update v_Exportar-BP.   
         
            if v_exportar-bp then
               update v_nivel-bp.
           
            v_tipo-encerramento = 'Anual'.
            sh-msg999-msg 
               = 'Pressione a setas direcionais para alternar a opcao'.
            run MostraMensagemC in this-procedure(0).
            Choose Field v_seletorTipoEncerramento Keys v_tipo-encerramento.
            v_tipo-encerramento  = Frame-Value.
            Color Display Message v_seletorTipoEncerramento[Frame-index].
            {msg999c.i &hide = yes} 
                
            if(v_exportar-bp   or
               v_exportar-dre    ) and
               v_mes-final ne 12   then 
               do.
                  v_ultimo-mes-demonstrativo = v_mes-final.
                  update v_ultimo-mes-demonstrativo with frame t4.
               end.

            update ws-arq-rtf.
         
            if ws-arq-rtf then 
               do.
                  sh-msg999-msg   
                     = idecademp0(sh-empresa)
                     + chr(10)
                     + fill(' ',18)
                     + 'Registro J800 devera ser inserido diretamente no PVA!'
                     .
                  run MostraMensagemA in this-procedure.
                  ws-arq-rtf = no.
                  next.
               end.
         
            update ws-exporta-DMPL.
            if ws-exporta-DMPL then
               run fho500ai.p ('dmp000').
            hide frame t1b no-pause.   
            leave. 
         end. /* bl-1 */
      if keyfunc(lastkey) = 'end-error' then next.
   
      if v_exercicio    >= 2014 and
        (v_Exportar-BP   = no   or 
         v_Exportar-Dre  = no)  then 
         do.
            sh-msg999-msg       
               = "Sera obrigatoria a geracao dos registros: "
               + chr(10)
               + "J100 --> Demonstracao do Balanco Patrimonial. "
               + chr(10)
               + "J150 --> Demonstracao do Resultado do Exercicio (DRE). " 
               + chr(10)
               + "Caso estas demonstracoes nao sejam informadas, poderam "
               + "ocorrer erros na hora da validacao do arquivo no PVA."
               .
            sh-msg999b-pergunta = 'Deseja continuar? Sim/Nao?'.
            ws-msg999-respdef   = no.
            run MostraMensagemB in this-procedure.
            if ws-msg999-respret = no then 
               next.
         end.

      leave.
   end. /*do while true*/

   if v_exercicio >= 2013 then     
      do while true
         with frame t1.
         clear frame t1b.  
         disp ws-ind-sit-ini-per.
             
         do with frame ind-ini-periodo.
            ws-keys = ws-acao-inv.
            pause 0.
            disp ws-ind-ini-v.
            choose field ws-ind-ini-v keys ws-keys.
            ws-ind-sit-ini-per  = substring(frame-value,1,1).
            disp ws-ind-sit-ini-per with frame t1.
            hide frame ind-ini-periodo no-pause.
         end.

         if not(ws-ind-sit-ini-per = "0"  or
            ws-ind-sit-ini-per     = "1"  or
            ws-ind-sit-ini-per     = "2"  or
            ws-ind-sit-ini-per     = "3") then 
            do.
               sh-msg999-msg   
                  = idecademp0(sh-empresa)
                  + chr(10)
                  + fill(' ',18)
                  + 'Valor do indicador do inicio do periodo invalido.'
                  + chr(10)
                  + chr(10)
                  + 'Favor verificar os valores validos:'
                  + chr(10)
                  + '   0 ==> Normal (inicio no primeiro dia do ano) 01/01/2011'
                  + chr(10)
                  + '   1 ==> Abertura 01/01/2011'
                  + chr(10)
                  + '   2 ==> Resultante de cisao/fusao ou remanescente de'
                  + chr(10)
                  + '         cisao, ou realizou incorporacao 01/01/2011'
                  + chr(10)
                  + '   3 ==> Inicio de obrigatoriedade da entrega da ECD no'
                  + chr(10)
                  + '         curso do ano calendario 01/01/2011.'
                  .
               run MostraMensagemA in this-procedure.
               next.
            end. 
            
         disp ws-ind-fin-esc.
         
         do with frame ind-fim-periodo.
            ws-keys = ws-acao-inv.
            pause 0.
            disp ws-ind-fim-v.
            choose field ws-ind-fim-v keys ws-keys.
            ws-ind-fin-esc  = int(substring(frame-value,1,1)).
            disp ws-ind-fin-esc with frame t1.
            hide frame ind-fim-periodo no-pause.
         end.
         
         update ws-num-retif.

         find first ecd091 share
            where ecd091.empresa   = sh-empresa
              and ecd091.cgc       = cademp.cgc
              and ecd091.mes-ref   = v_mes-inicial
              and ecd091.ano-ref   = v_exercicio
              and ecd091.num-retif = ws-num-retif
            no-error.
         if not avail ecd091 then 
            do.
               create ecd091.
               assign 
                  ecd091.empresa   = sh-empresa
                  ecd091.cgc       = cademp.cgc
                  ecd091.mes-ref   = v_mes-inicial
                  ecd091.ano-ref   = v_exercicio
                  ecd091.num-retif = ws-num-retif
                  .
            end.
         else 
            bloco-10:
            repeat   
               on endkey undo bloco-0, next bloco-0.
               if ws-ind-fin-esc = 0 then 
                  leave.

               update ws-cod-hash-sub form "x(40)" with frame t6a.
               ws-cod-hash-sub = caps(ws-cod-hash-sub).
               disp ws-cod-hash-sub with frame t6a. 
               pause 0.
               y = "A,B,C,D,E,F,1,2,3,4,5,6,7,8,9,0".
               
               do i = 1 to 40.
                  if can-do(y, substring(ws-cod-hash-sub,i,1)) = no then 
                     do.
                        sh-msg999-msg   
                           = idecademp0(sh-empresa)
                           + chr(10)
                           + fill(' ',18)
                           + 'Caractere "'
                           + substring(ws-cod-hash-sub,i,1) 
                           + '" invalido.'
                           + chr(10)
                           + chr(10)
                           + '-Caracteres validos:  '
                           + y
                           + chr(10)
                           + "-E o campo deve possuir 40 caracteres."
                           .
                        run MostraMensagemA in this-procedure.
                        next bloco-10.    
                     end.
               end.
               hide frame t6a.
               leave.   
            end.

         if ws-ind-fin-esc = 3 then 
            bloco-11:
            repeat
               on endkey undo bloco-0, next bloco-0:

               update ws-nire-subst with frame t6b.
               y = "1,2,3,4,5,6,7,8,9,0".
               
               do i = 1 to 11.
                  if can-do(y, substring(ws-nire-subst,i,1)) = no then 
                     do.
                        sh-msg999-msg
                           = idecademp0(sh-empresa)
                           + chr(10)
                           + fill(' ',18)
                           + 'Caractere "'
                           + substring(ws-nire-subst,i,1)
                           + '" invalido.'
                           + chr(10)
                           + chr(10)
                           + '-Caracteres validos:  '
                           + y
                           .
                        run MostraMensagemA in this-procedure.
                        next bloco-11.
                     end. 
               end.
                  
               if ws-nire-subst = "" then 
                  do. 
                     sh-msg999-msg   
                        = idecademp0(sh-empresa)
                        + chr(10)
                        + fill(' ',18)
                        + 'Se o campo 14-Ind.ini.periodo for preenchido "
                        + "com 1'
                        + ' ou 3, deve ser informado o NIRE Anterior.'.
                     run MostraMensagemA in this-procedure.
                     next.
                  end.
               hide frame t6b.
               leave.
            end.

         B-9:
         do while true
            with frame t1.
                                  
            if v_exercicio >= 2014 then
               ws-dt-ex-social = date(12,31,v_exercicio).
                                    
            update ws-dt-ex-social.
         
            if ws-dt-ex-social  = ?    and
               v_exercicio     >= 2014 then 
               do.
                  sh-msg999-msg 
                     = idecademp0(sh-empresa)
                     + chr(10)
                     + fill(' ',18)
                     + " A data do exercicio social ‚ obrigatoria."
                     + chr(10)
                     .
                  run MostraMensagemA in this-procedure.
                  next B-9.
               end.
            leave.
         end.
         leave.
      end.
   
   sh-msg999-msg
      = ws-ide-filtro
      + chr(10)
      + 'Arquivo.........: '
      + ws-nome-arq
      .
   sh-msg999b-pergunta = 'Confirma exportacao dos dados? Sim/Nao?'.
   ws-msg999-respdef = no.
   run MostraMensagemB in this-procedure.
   if ws-msg999-respret = no then 
         undo bloco-0, next bloco-0.

   if search(ws-nome-arq) <> ? then
      do.
         run MostraMensagem('APAGANDO ARQUIVO ' + ws-nome-arq).
         os-command silent value ('rm -rf ' + ws-nome-arq).
      end.   
      
   run GravaLog005 in this-procedure.

   run MostraMensagem('CARREGANDO DADOS DA CONTABILIDADE').
   
   ws-procedure = ''.
   bloco-1:
   repeat.
      sh-msg999-msg = 'VERIFICANDO PLANO DE CONTAS'.
      run MostraMensagemC in this-procedure(0).
      ws-msg999-aux = ''.
      for each ctb001 use-index ctb001-4 
         where ctb001.empresa = sh-empresa
           and ctb001.tipo    = no 
         on error undo bloco-1, leave bloco-1.
         find first ctb001a
            where ctb001a.empresa  = ctb001.empresa
              and ctb001a.superior =  ctb001.conta
            no-error.
         if avail ctb001a = yes then    
            do.
               ws-msg999-aux 
                  = ws-msg999-aux
                  + chr(10)
                  + string(ctb001.conta,'x(17)')
                  + ' '
                  + string(ctb001.tipo,'Sintetica/Analitica')
                  + ' '
                  + string(ctb001a.conta,'x(17)')
                  .
            end. 
      end.   
      if ws-msg999-aux <> '' then
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + idetxt002(18,58,'',''
               + 'Foi encontrada inconsistencia em algumas contas contabeis.'
               + chr(10)
               + 'Algumas contas analiticas estao marcadas como sistenticas.'
               + chr(10)
               + 'Utilize a rotina ctb203.p para corrigir.')
               + chr(10)
               + 'Conta             Tipo      Conta Analitica'
               + ws-msg999-aux
               .
            run MostraMensagemA in this-procedure.
            undo bloco-1, leave bloco-1.
         end.

      run MostraMensagem('CARREGANDO DADOS DO BLOCO 0').
      sh-msg999-msg = 'CARREGANDO REGISTRO: 0000'.
      run MostraMensagemC in this-procedure(0). 
      run CarregaTMP0000 in this-procedure no-error.
      if return-value <> 'CarregaTMP0000_ok' then 
         do.
            ws-procedure = 'CarregaTMP0000'.
            undo bloco-1, leave bloco-1.
         end.
      if ws-exporta-DMPL = yes then 
         do.
            sh-exercicio = v_exercicio.
            pause 0.
            sh-msg999-msg = 'CARREGANDO REGISTRO: J200'.
            run MostraMensagemC in this-procedure(0). 
            run ecd501b.p no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPJ200'.
                  undo bloco-1, leave bloco-1.
               end.
         end.
       
      if ws-arq-rtf = yes then 
         do.
            ws-linha = 0.   
            for each tt-arquivo
               where tt-arquivo.marca = yes.
               v_LinhaImport = ''.
                  
               input from value(ws-diretorio + tt-arquivo.arquivo).
               repeat.
                  v_LinhaImport = ''.
                      
                  import unformatted v_LinhaImport.
                  replace(v_LinhaImport,chr(10),'').
                     
                  ws-linha = ws-linha + 1.
                      
                  find first tmpj800a
                     where tmpj800a.linha = ws-linha
                     no-error.
                  if not avail tmpJ800a then 
                     do.
                        create tmpJ800a.
                        assign
                           tmpJ800a.linha       = ws-linha
                           tmpJ800a.conte_linha = v_LinhaImport
                           .
                     end.
                  else 
                     do.
                        assign
                           tmpJ800a.linha       = ws-linha
                           tmpJ800a.conte_linha = v_LinhaImport
                           .
                     end.               
                           
                  find first tmpJ800
                     where tmpJ800.reg     = 'J800'
                       and tmpJ800.arquivo = tt-arquivo.arquivo
                     no-error.
                  if not avail tmpJ800 then 
                     do.
                        create tmpJ800.
                        assign
                           tmpJ800.reg         = 'J800'
                           tmpJ800.arquivo     = tt-arquivo.arquivo
                           tmpJ800.IND_FIM_RTF = 'J800FIM'
                           .
                        run CarregaTMPI030 in this-procedure no-error.
                        run Carregatmp9900 in this-procedure(input "J800")
                            no-error.
                     end.
               end.
               input close.
            end.
         end. 
          
      run MostraMensagem('CARREGANDO DADOS DO BLOCO 0').
      if trim(v_condicaoContabilidade) = 'Descentralizada' then 
         do.
            sh-msg999-msg = 'CARREGANDO REGISTRO: 0020'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTMP0020 in this-procedure no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMP0020'.
                  undo bloco-1, leave bloco-1.
               end.
         end.
      
      run MostraMensagem('CARREGANDO DADOS DO BLOCO I').
      sh-msg999-msg = 'CARREGANDO REGISTRO: I001'.
      run MostraMensagemC in this-procedure(0). 
      run CarregaTMPI001 in this-procedure no-error.
      if return-value <> 'CarregaTMPI001_ok' then 
         do.
            ws-procedure = 'CarregaTMPI001'.
            undo bloco-1, leave bloco-1.
         end.
      
      sh-msg999-msg = 'CARREGANDO REGISTRO: I010'.
      run MostraMensagemC in this-procedure(0). 
      run CarregaTMPI010 in this-procedure no-error.
      if error-status:error then 
         do.
            ws-procedure = 'CarregaTMPI010'.
            undo bloco-1, leave bloco-1.
         end.
      
      /*********************************************************/
      sh-msg999-msg = 'CARREGANDO REGISTRO: I030'.
      run MostraMensagemC in this-procedure(0). 
      run Carregatmp9900 in this-procedure (input "I030") no-error.
      if v_tipo-livro <> "Z" then 
         do.
            run CarregaTMPI050 in this-procedure no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPI050'.
                  undo bloco-1, leave bloco-1.
               end.
         end.    
            
      if can-find(first tmp001) then 
         do.
            sh-msg999-msg
               = ' Atencao! Ha erros nos dados para exportacao ECD. '
               .
            sh-msg999b-pergunta = 'Deseja verificar?'.
            run MostraMensagemB in this-procedure.
            if sh-msg999-resp then
               RUN relatorio-erro in this-procedure.
            leave bloco-1.
         end.    
                     
      sh-msg999-msg = 'CARREGANDO REGISTRO: I150'.
      run MostraMensagemC in this-procedure(0). 
      run CarregaTMPI150 in this-procedure no-error.
      if error-status:error then 
         do.
            ws-procedure = 'CarregaTMPI150'.
            undo bloco-1, leave bloco-1.
         end.
            
      sh-msg999-msg = 'CARREGANDO REGISTRO: I155'.
      run MostraMensagemC in this-procedure(0). 
      run CarregaTMPI155 in this-procedure no-error.
      if error-status:error then 
         do.
            ws-procedure = 'CarregaTMPI155'.
            undo bloco-1, leave bloco-1.
         end.
      
      if v_tipo-livro <> 'Z' then 
         do.      
            if not ws-oculta-lctos-estorno then 
               do.
                  sh-msg999-msg = 'CARREGANDO REGISTRO: I220'.
                  run MostraMensagemC in this-procedure(0). 
                  run CarregaTMPI200 in this-procedure no-error.
                  if error-status:error then 
                     do.
                        ws-procedure = 'CarregaTMPI200'.
                        undo bloco-1, leave bloco-1.
                     end.
               end.
            else 
               do.
                  sh-msg999-msg = 'CARREGANDO REGISTRO: I220'.
                  run MostraMensagemC in this-procedure(0). 
                  run CarregaTMPI200-Sem-Estorno in this-procedure no-error.
                  if error-status:error then 
                     do.
                        ws-procedure = 'CarregaTMPI200'.
                        undo bloco-1, leave bloco-1.
                     end.
               end.
            sh-msg999-msg = 'CARREGANDO REGISTRO: I350'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTMPI350 in this-procedure no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPI350'.
                  undo bloco-1, leave bloco-1.
               end.
         end.

      if v_Tipo-Livro <> "G" then 
         do.
            sh-msg999-msg = 'CARREGANDO REGISTRO: I012'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTMPI012 in this-procedure no-error.   
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPI012'.
                  undo bloco-1, leave bloco-1. 
               end.

            sh-msg999-msg = 'CARREGANDO REGISTRO: I015'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTMPI015 in this-procedure no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPI015'.
                  undo bloco-1, leave bloco-1.
               end.
         end.
      /******************************/
      run MostraMensagem('CARREGANDO DADOS DO BLOCO J').
      sh-msg999-msg = 'CARREGANDO REGISTRO: J001'.
      run MostraMensagemC in this-procedure(0). 
      run CarregaTMPJ001 in this-procedure no-error.
      if error-status:error then 
         do.
            ws-procedure = 'CarregaTMPJ001'.
            undo bloco-1, leave bloco-1.
         end.
                
      iF v_Exportar-Dre or 
         v_Exportar-BP then 
         do.
            sh-msg999-msg = 'CARREGANDO REGISTRO: J005'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTmpJ005 in this-procedure no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPJ005'.
                  undo bloco-1, leave bloco-1.
               end.
         end.
      if v_Exportar-Dre then 
         do.
            sh-msg999-msg = 'CARREGANDO REGISTRO: J150'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTMPJ150 in this-procedure no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPJ150'.
                  undo bloco-1, leave bloco-1.
               end.
         end.
      
      run MostraMensagem('CARREGANDO DADOS DO BLOCO J').
      if v_Exportar-BP then 
         do.
            sh-msg999-msg = 'CARREGANDO REGISTRO: J100'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTMPJ100 in this-procedure no-error.
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPJ100'.
                  undo bloco-1, leave bloco-1.
               end.
         end.
      
      run MostraMensagem('CARREGANDO DADOS DO BLOCO J').
      sh-msg999-msg = 'CARREGANDO REGISTRO: J930'.
      run MostraMensagemC in this-procedure(0). 
      run CarregaTMPJ930 in this-procedure no-error. 
      if error-status:error then 
         do.
            ws-procedure = 'CarregaTMPJ930'.
            undo bloco-1, leave bloco-1.
         end. 
       
      if v_exercicio >= 2014       and 
         ws-entidade-suj-auditoria then 
         do.
            sh-msg999-msg = 'CARREGANDO REGISTRO: J935'.
            run MostraMensagemC in this-procedure(0). 
            run CarregaTMPJ935 in this-procedure no-error. 
            if error-status:error then 
               do.
                  ws-procedure = 'CarregaTMPJ935'.
                  undo bloco-1, leave bloco-1.
               end. 
         end.   
             
      if can-find(first tmp001) then leave.
      
      if ws-procedure <> '' then leave.
      
      run MostraMensagem('PROCESSANDO AJUSTES FINAIS').
      sh-msg999-msg = ''.
      run MostraMensagemC in this-procedure(0). 
      run AjustesFinais in this-procedure.
      if return-value <> 'AjustesFinais_ok' then 
         do.
            ws-procedure = 'AjustesFinais'. 
            leave.
         end.   
      
      run MostraMensagem('GERANDO ARQUIVO').
      run ExportaECD in this-procedure ('') no-error.
      if return-value <> 'ExportaECD_ok' then 
         do.
            if search(ws-nome-arq) <> ? then
               repeat.
                  os-command silent value ('rm -rf ' + ws-nome-arq).
                  leave.
               end.
            ws-procedure = 'ExportaECD'. 
            leave.
         end.   
         
      sh-msg999-msg   
         = idecademp0(sh-empresa)
         + chr(10)
         + fill(' ',18)
         + 'ARQUIVO EXPORTADO !!!' 
         + chr(10) 
         + chr(10) 
         + '              EM: ' 
         + ws-nome-arq
         .
      run MostraMensagemA in this-procedure.
      ws-procedure = ''.
      leave.
   end.

   if ws-procedure <> '' then 
      do.
         pause 0.
         sh-msg999-msg   
            = idecademp0(sh-empresa)
            + chr(10)
            + fill(' ',18)
            + 'Houve erro na procedure ' 
            + ws-procedure
            .
         run MostraMensagemA in this-procedure.
         undo, next.
      end.
  
   if can-find(first tmp001) then 
      do.
         sh-msg999-msg = ' Atencao! Ha erros nos dados para exportacao ECD.'.
         sh-msg999b-pergunta = 'Deseja verificar?'.
         run MostraMensagemB in this-procedure.
         if sh-msg999-resp then
            run relatorio-erro in this-procedure.
         undo, next.  
      end.

end.
put screen row 22 col 64 fill(' ',16).
end procedure.  /* GerarArquivoECD */

/*------------------------------------------------------------------------*/
procedure AjustesFinais.
def var ws-debito                      like tmpI250.VL_DC.
def var ws-credito                     like tmpI250.VL_DC.
def var ws-ativo                       like tmpI250.VL_DC.
def var ws-passivo                     like tmpI250.VL_DC.
def var ws-resultado                   like tmpI250.VL_DC.

   bloco-1:
   repeat:
      sh-msg999-msg = 'Ajustando registros I050, I051, I052, I155, J100'.
      run MostraMensagemC in this-procedure(0). 
      /*run ExportaDadosParaTeste in this-procedure.*/
      for each tmpI050 use-index tmpi050-2
         where tmpI050.reg     = 'I050'
           and tmpI050.ind_cta = 'A'
           and tmpI050.nivel   = 3
           and(tmpI050.COD_CTA begins '1'   or  
               tmpI050.COD_CTA begins '2'   ).
         
         find first tmpI050b
            where tmpI050b.COD_CTA_SUP = tmpI050.COD_CTA 
              no-error.
         if avail tmpI050b then
            do.
               sh-msg999-msg
                  = ws-ide-filtro
                  + chr(10)
                  + fill(' ',18)
                  + 'Conta Contabil..: ' 
                  + tmpI050.COD_CTA 
                  + chr(10)
                  + fill(' ',18)
                  + 'Conta contabil sintetica marcada com analitica.'
                  + chr(10)
                  + fill(' ',18)
                  + 'Verifique o cadastro de contas contabeis.' 
                  .
               run MostraMensagemA in this-procedure.
               next.
            end.
         create tmpI050b.
         buffer-copy tmpI050 to tmpI050b.
         assign
            tmpI050b.COD_CTA     = tmpI050.COD_CTA + '01'
            tmpI050b.COD_CTA_SUP = tmpI050.COD_CTA
            tmpI050b.nivel       = 4
            tmpI050b.programa    = program-name(1)
            .
            
         run CarregaTMPI030 in this-procedure                no-error.
         run Carregatmp9900 in this-procedure (input "I050") no-error.
            
         tmpI050.ind_cta     = 'S'.
         tmpI050.IND_COD_AGL = 'T'.
         
         find first tmpI051
            where tmpI051.reg      = 'I051'
              and tmpI051.cod_cta  = tmpI050.COD_CTA
            no-error.
         if avail tmpI051 then 
            tmpI051.cod_cta = tmpI050b.COD_CTA.
         
         find first tmpI052
            where tmpI052.reg      = 'I052'
              and tmpI052.COD_CTA  = tmpI050.COD_CTA
            no-error.
         if avail tmpI052 then 
            do.
               for each tmpJ100
                  where tmpJ100.reg       = 'J100'
                    and tmpJ100.COD_AGL   = tmpI052.COD_AGL.
       
                  create tmpJ100b.
                  buffer-copy tmpJ100 to tmpJ100b.
                  assign
                     tmpJ100b.COD_AGL     = tmpI050b.COD_CTA
                     tmpJ100b.COD_AGL_SUP = tmpI050b.COD_CTA_SUP
                     tmpJ100b.NiVEL_AGL   = tmpI050b.nivel
                     .
                  
                  tmpJ100.IND_COD_AGL = 'T'.

                  run CarregaTMPI030 in this-procedure no-error.
                  run Carregatmp9900 in this-procedure (input "J100") no-error.
               end.
            
               assign
                  tmpI052.cod_cta = tmpI050b.COD_CTA
                  tmpI052.COD_AGL = tmpI050b.COD_CTA.
            end.
       
         for each tmpI155 use-index tmpi155-1
            where tmpI155.reg     = 'I155'
              and tmpI155.COD_CTA = tmpI050.COD_CTA.
            
            tmpI155.COD_CTA = tmpI050b.COD_CTA. 
         end.          
         
         for each tmpI250
            where tmpI250.reg     = 'I250'
              and tmpI250.COD_CTA = tmpI050.COD_CTA.
            
            tmpI250.COD_CTA = tmpI050b.COD_CTA.
         end.
      end.
 
      run CarregatmpI990 in this-procedure no-error.
      run CarregatmpJ990 in this-procedure no-error.
      run Carregatmp9001 in this-procedure no-error.
      run Carregatmp9990 in this-procedure no-error.
      run Carregatmp9999 in this-procedure no-error.

      for each tmp9900
         where tmp9900.reg = "9900".
         run CarregaTMPI030 in this-procedure no-error.
      end.
       
      run CarregaTMPJ900 in this-procedure no-error.
      
      sh-msg999-msg = 'Consistindo saldos I155 e I250'.
      run MostraMensagemC in this-procedure(0). 
      ws-msg999-aux = ''.
      ws-msg999-au1 = ''.
      for each tmpI250 use-index tmpI250-2
         break 
            by tmpI250.COD_CTA
            by tmpI250.COD_CCUS
            by year(tmpI250.dt_lcto)
            by month(tmpI250.dt_lcto)
            .
         
         if first-of(month(tmpI250.dt_lcto)) then 
            do.
               ws-credito = 0.
               ws-debito  = 0.
            end.

         if tmpI250.IND_DC = 'C' then 
            ws-credito = ws-credito + tmpI250.VL_DC.
         else
            ws-debito  = ws-debito  + tmpI250.VL_DC.
            
         if last-of(month(tmpI250.dt_lcto)) then
            do.
               find first tmpI155
                  where tmpI155.reg     = 'I155' 
                    and tmpI155.cod_cta = tmpI250.COD_CTA
                    and tmpI155.COD_CCUS= tmpI250.COD_CCUS
                    and tmpI155.mes     = month(tmpI250.dt_lcto)
                  no-error.
               if avail tmpI155 = no then
                  do.
                     if ws-debito <> 0 then 
                     if length(ws-msg999-au1) < 10000 then 
                        ws-msg999-au1
                           = ws-msg999-au1
                           + chr(10)
                           + string(month(tmpI250.dt_lcto),'z99')
                           + ' '
                           + string(tmpI250.cod_cta,'x(17)')
                           + ' '
                           + string(tmpI250.COD_CCUS,'x(8)')
                           + ' D ' 
                           + fill(' ',16)
                           + string(ws-debito,'zzz,zzz,zz9.99')
                           .
                     if ws-credito <> 0 then       
                     if length(ws-msg999-au1) < 10000 then 
                        ws-msg999-au1
                           = ws-msg999-au1
                           + chr(10)
                           + string(month(tmpI250.dt_lcto),'z99')
                           + ' '
                           + string(tmpI250.cod_cta,'x(17)')
                           + ' '
                           + string(tmpI250.COD_CCUS,'x(8)')
                           + ' C '
                           + fill(' ',16)
                           + string(ws-credito,'zzz,zzz,zz9.99') 
                           .
                  end.
               else
                  do.
                     if tmpI155.VL_DEB <> ws-debito then 
                     if length(ws-msg999-aux) < 10000 then 
                        ws-msg999-aux 
                           = ws-msg999-aux
                           + chr(10)
                           + string(tmpI155.mes,'z99')
                           + ' '
                           + string(tmpI155.cod_cta,'x(17)')
                           + ' ' 
                           + string(tmpI155.COD_CCUS,'x(8)')
                           + ' D ' 
                           + string(tmpI155.VL_DEB,'zzz,zzz,zz9.99')
                           + '  '
                           + string(ws-debito,'zzz,zzz,zz9.99')
                           .
                     if tmpI155.VL_CRED <> ws-credito then 
                     if length(ws-msg999-aux) < 10000 then 
                        ws-msg999-aux 
                           = ws-msg999-aux
                           + chr(10)
                           + string(tmpI155.mes,'z99')
                           + ' '
                           + string(tmpI155.cod_cta,'x(17)')
                           + ' ' 
                           + string(tmpI155.COD_CCUS,'x(8)')
                           + ' C '
                           + string(tmpI155.VL_CRED,'zzz,zzz,zz9.99')
                           + '  '
                           + string(ws-credito,'zzz,zzz,zz9.99')
                           .
                     end.
            end.
      end.

      if ws-msg999-au1 <> '' then
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + fill(' ',18)
               + 'Nao gerou registro I155 para algumas contas.'
               + chr(10)
               + 'Mes Conta Contabil    C.Custo  T '
               + '          Valor Acumulado I250' 
               + ws-msg999-au1
               .
            run MostraMensagemA in this-procedure.
         end.
      
      if ws-msg999-aux <> '' then
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + fill(' ',18)
               + 'Alguns registro I155 estao com diferenca para os I250.'
               + chr(10)
               + 'Mes Conta Contabil    C.Custo  T '
               + '    Valor I155      Valor I250' 
               + ws-msg999-aux
               .
            run MostraMensagemA in this-procedure.
         end.
      ws-msg999-aux = ''.
      for each tmpI155
         where tmpI155.reg     = 'I155' 
         break 
            by tmpI155.cod_cta
            by tmpI155.COD_CCUS
            by tmpI155.mes
         .
         /*
         if tmpI155.IND_DC_INI = 'D' then dci = 1. else dci = -1.
         if tmpI155.IND_DC_FIN = 'D' then dcf = 1. else dcf = -1.
         ws-saldof 
            =(tmpI155.VL_SLD_INI * dcf) + tmpI155.VL_DEB - tmpI155.VL_CRED.

         if ws-saldof <> (tmpI155.VL_SLD_FIN * dcf) then 
         */
         if tmpI155.VL_SLD_FIN <> tmpI155.VL_SLD_INI +
                                  tmpI155.VL_DEB     -
                                  tmpI155.VL_CRED      then
         if length(ws-msg999-aux) < 10000 then 
            do.
               ws-msg999-aux
                  = ws-msg999-aux
                  + chr(10)
                  + string(tmpI155.cod_cta,'x(16)')
                  + ' '
                  + string(tmpI155.mes,'z99')
                  + string(tmpI155.VL_SLD_INI,'zzzzzzz,zz9.99-')
                  + string(tmpI155.VL_DEB,'zzzzzz,zz9.99')
                  + string(tmpI155.VL_CRED,'zzzzzz,zz9.99')
                  + string(tmpI155.VL_SLD_FIN,'zzzzzz,zz9.99-')
                  .
            end.
      end.
      
      if ws-msg999-aux <> '' then
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + fill(' ',18)
               + 'Alguns registro I155 estao com diferenca entre '
               + chr(10)
               + fill(' ',18)
               + 'o saldo final e saldo inicial + debitos - creditos'
               + chr(10)
               + 'Conta Contabil   Mes '
               + 'Saldo Inicial        Debito      Credito    Sld Final' 
               + ws-msg999-aux
               .
            run MostraMensagemA in this-procedure.
         end.

      assign
         ws-msg999-aux = ''
         ws-ativo      = 0
         ws-passivo    = 0
         ws-resultado  = 0
         .
      for each tmpI155
         where tmpI155.reg     = 'I155' 
         .
         if tmpI155.cod_cta begins '1' then 
            ws-ativo     = ws-ativo     + tmpI155.VL_SLD_FIN.
         if tmpI155.cod_cta begins '2' then 
            ws-passivo   = ws-passivo   + tmpI155.VL_SLD_FIN.
         if tmpI155.cod_cta begins '3' then 
            ws-resultado = ws-resultado + tmpI155.VL_SLD_FIN.
      end.
      if ws-ativo + ws-passivo + ws-resultado <> 0 then 
         do.
            sh-msg999-msg
               = ws-ide-filtro
               + chr(10)
               + 'Ativo...........: ' + string(ws-ativo,'zzz,zzz,zz9.99-')
               + chr(10)
               + 'Passivo.........: ' + string(ws-passivo,'zzz,zzz,zz9.99-')
               + chr(10)
               + 'Resultado.......: ' + string(ws-resultado,'zzz,zzz,zz9.99-')
               + chr(10)
               + 'Diferenca.......: ' 
               + string(ws-ativo + ws-passivo + ws-resultado,'zzz,zzz,zz9.99-')
               + chr(10)
               + fill(' ',18)
               + 'A soma das contas ativo, passivo e resultado nao ' 
               + chr(10)
               + fill(' ',18)
               + 'esta zerando.'
               .
            run MostraMensagemA in this-procedure.
         end.
   
      sh-msg999-msg = ''.
      run MostraMensagemC in this-procedure(0). 
      
      return 'AjustesFinais_ok'.
   end.
end procedure. /*AjustesFinais*/

Procedure Conta-linha. 
   b1:
   do
      on endkey undo, leave b1 
      on error undo, leave b1.
   
      v_total-linha = 0.
                                     
      input stream s1 from value((ws-nome-arq + '-cont')).
      repeat
         on endkey undo, leave
         on error undo, leave.
                
         import stream s1 unformatted v_LinhaImport.
         v_total-linha = v_total-linha + 1.
      end.
                         
      input stream s1 close.
      pause 0.
      if search(ws-nome-arq + '-cont') <> ? then
         os-command silent value ('rm -rf ' + (ws-nome-arq + '-cont')).
      pause 0.
   
   End.
End Procedure. /*Conta-linha*/

procedure seletor-conta-encerramento.
   b1:
   repeat 
      on error  undo b1, return
      on endkey undo b1, return.
   
      {choose.i
         &File   = ctb001
         &Z      = ctb001
         &Lock   = "no-lock "
         &index  = "use-index ctb001-1"
         &Where  = "ctb001.empresa   = sh-empresa"
         &Where1 = "ctb001.conta  begins '3' "          
         &CField = ctb001.conta
         &Ofield = "
                   ctb001.conta
                   ctb001.descricao
                   "
         &down   = 10
         &Row    =  7
         &Keyf   = "cursor-left,cursor-right,recall,go,get"
         &Help   = "<F1>-Altera Unidade"
         &disp   = " "
         }.

      if keyfunc(lastkey) eq 'end-error' then
         return.
 
      return ctb001.conta.       
   end.
end procedure. /*seletor-conta-encerramento*/

procedure SeletorArquivos. 
   for first TT-Arquivo.
      r-TT-Arquivo = recid(TT-Arquivo).
   end.
   do while true 
      with frame t-rotinas.  
      {choose.i
         &choose.w = */
         &Z      = TT-Arquivo
         &File   = TT-Arquivo
         &Index  = "use-index Chave-Arquivo"
         &CField = TT-Arquivo.Arquivo
         &Ofield = "TT-Arquivo.Usuario
                    TT-Arquivo.marca
                    TT-Arquivo.Arquivo form 'x(20)'
                    TT-Arquivo.Tamanho
                    TT-Arquivo.Mes
                    TT-Arquivo.Dia
                    TT-Arquivo.Hora
                    "
         &Keyf   = "cursor-left,cursor-right, ,+,-"
         &Select = "if can-do(' ,,return',keyfunc(lastkey)) then do.
                       TT-Arquivo.marca = not TT-Arquivo.marca.
                       disp TT-Arquivo.marca.
                       assign TT-Arquivoz-leave = no
                       TT-Arquivoz-keyf = 'cursor-down'
                       TT-Arquivoz-keyl = 'cursor-down'.
                    end.
                   "
         &Down   = 13
         &Row    = 4
         &Hiden  = no
         &Help   = "<Enter>Marca/Desmarca <+>Marca todos ' +
                    '<->Desmarca todos  <F1>Continua"
         &Form   = "frame t-rotinas
                     title 'SELECIONA ARQUIVOS' "
         }.

      if can-do('-',keyfunc(lastkey)) then 
         do.
            for each TT-Arquivo.
               TT-Arquivo.marca = no.
            end.
            next.
         end.
      if can-do('+',keyfunc(lastkey)) then 
         do.
            for each TT-Arquivo.
              TT-Arquivo.marca = yes.
            end.
            next.
         end.
      hide frame t-conta no-pause.
      hide frame t-rotinas no-pause.
      leave.
   end.
end procedure. /*SeletorArquivos*/

procedure GravaLog005.
def var ws-img-filtro as cha.   
   b1:
   repeat.
      ws-img-filtro 
         = 'Tela 01'
         + chr(10) + 'Empresa.........: ' + string(sh-empresa) 
         + chr(10) + 'Unidade.........: ' + string(ws-unidade) 
                   + ' ' + string(cademp.sigla,'x(23)')
                   + fill(' ',2)
                   + 'Data ato Constituicao: ' 
                   + string(v-data-constituicao,'99/99/9999')
         + chr(10) + 'Mes Inicial.....: ' + string(v_mes-inicial)
                   + fill(' ',26)
                   + 'Data ato Conversao...: ' 
                   +(if v-data-conversao = ? then '[?]'
                     else string(v-data-conversao,'99/99/9999'))
         + chr(10) + 'Mes Final.......: ' + string(v_mes-final)
                   + fill(' ',25)
                   + 'Numero do livro......: ' + string(v-num-livro)
         + chr(10) + 'Ano Referencia..: ' + string(v_exercicio)
                   + fill(' ',23)
                   + 'Oculta Estorno.......: ' 
                   + string(ws-oculta-lctos-estorno,'Sim/Nao')
         + chr(10) + 'Faz Encerramento: ' + string(v_Encerramento,'Sim/Nao')
                   + fill(' ',24)
                   + 'Lote Do Encerramento.: ' + string(v_LoteEncerramento)
         + chr(10) + 'Nome Arquivo....: ' + string(ws-nome-arq)
         + chr(10) + 'Demonstrativos..: ' + string(ws-demonstrativos,'Sim/Nao')
         + chr(10) + 'Ind.ini.periodo.: ' + string(ws-ind-sit-ini-per)
         + chr(10) + 'Ind.fin.escricao: ' + string(ws-ind-fin-esc)
         + chr(10) + 'Num. retificacao: ' + string(ws-num-retif)
         + chr(10) + 'Data Enc.Ex.Soc.: ' 
                   + string(ws-dt-ex-social,'99/99/9999')
         .
      if ws-demonstrativos = no then 
         do.
            ws-img-filtro
               = ws-img-filtro 
               + chr(10) + 'Encerramento....: Anual' 
               .
         end.
      else
         do.
            ws-img-filtro
               = ws-img-filtro
               + chr(10)
               + chr(10)
               + 'Tela 02' 
               + chr(10) + 'Exportar D.R.E....: ' 
                         + string(v_Exportar-Dre,'Sim/Nao') + ' '
                         + 'Plano Contas ...: ' + string(ws-plano-dre) + ' '
                         +(if avail dre001 then 
                              string(dre001.descricao,'x(30)') else '')
               + chr(10) + 'D.R.E Consolidado.: ' 
                         + string(ws-consolidado,'Sim/Nao')
               + chr(10) + 'Exportar B.P......: ' 
                         + string(v_Exportar-BP,'Sim/Nao') + ' '
                         + 'Nivel B.P.......: ' + string(v_nivel-bp)
               + chr(10) + 'Encerramento......: ' 
                         + trim(string(v_tipo-encerramento))
               + chr(10) + 'Outras Inf. (J800): ' 
                         + string(ws-arq-rtf,'Sim/Nao')
               + chr(10) + 'Exporta DMPL......: ' 
                         + string(ws-exporta-DMPL,'Sim/Nao')
               .
         end.      
      create log005.
      assign
         log005.programa  = 'ecd501.p'
         log005.FiltroTxt = ws-img-filtro
         .
      /*update log005.FiltroTxt view-as editor size 78 by 15 with overlay.*/
      leave.
   end.
end procedure. /*GravaLog005*/
/*
procedure ExportaDadosParaTeste.
      output to tmpI050.d.
      for each tmpI050 use-index tmpi050-2
         where tmpI050.reg     = 'I050'
           and tmpI050.ind_cta = 'A'
           and tmpI050.nivel   = 3
           and tmpI050.COD_CTA begins '15'.   
         export tmpI050.
      end.
      output close.
      output to tmpI051.d.
      for each tmpI050 use-index tmpi050-2
         where tmpI050.reg     = 'I050'
           and tmpI050.ind_cta = 'A'
           and tmpI050.nivel   = 3
           and tmpI050.COD_CTA begins '15'.   
         find first tmpI051
            where tmpI051.reg      = 'I051'
              and tmpI051.cod_cta  = tmpI050.COD_CTA
            no-error.
         if avail tmpI051 then 
         export tmpI051.
      end.
      output close.
      output to tmpI052.d.
      for each tmpI050 use-index tmpi050-2
         where tmpI050.reg     = 'I050'
           and tmpI050.ind_cta = 'A'
           and tmpI050.nivel   = 3
           and tmpI050.COD_CTA begins '15'.   
         find first tmpI052
            where tmpI052.reg      = 'I052'
              and tmpI052.COD_CTA  = tmpI050.COD_CTA
            no-error.
         if avail tmpI052 then 
            export tmpI052.
      end.
      output close.
      output to tmpj100.d.
      for each tmpI050 use-index tmpi050-2
         where tmpI050.reg     = 'I050'
           and tmpI050.ind_cta = 'A'
           and tmpI050.nivel   = 3
           and tmpI050.COD_CTA begins '15'.   
         find first tmpI052
            where tmpI052.reg      = 'I052'
              and tmpI052.COD_CTA  = tmpI050.COD_CTA
            no-error.
         if avail tmpI052 then 
            do.
               for each tmpJ100
                  where tmpJ100.reg       = 'J100'
                    and tmpJ100.COD_AGL   = tmpI052.COD_AGL.
       
                   export tmpj100.
               end.
            end.
      end.
      output close.
end oprocedure. /*ExportaDadosParaTeste*/
*/ 
&Endif 
