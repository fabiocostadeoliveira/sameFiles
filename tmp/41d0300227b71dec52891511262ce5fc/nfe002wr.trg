/*---------------------------------------------------------------------------*\
 *                   D A T A C O P E R     S O F T W A R E                   *
\*---------------------------------------------------------------------------*/
/*---------------------------------------------------------------------------*\
  Sistema....: 03 - Vendas
  Subsistema.: XX - Nota Fiscal Eletronica
  Programa...: nfe002wr.trg
  Objetivo...: Trigger de write do nfe002 - retorno do comunicador / Sefaz
  Responsavel: Carlos Eduardo Justino
  Data.......: 25/02/2014
  Solicitacao: 114628
\*---------------------------------------------------------------------------*/
&if defined(RetornarVersao_nfe002wr_trg) > 0 &then
   &GLOBAL Versao_nfe002wr_trg 2014.02.27
&else
{ver500aa.i &Arquivo = nfe699 &Extensao = p &VersaoBase = 2012.04.12}.
{ver500aa.i &Arquivo = nfe099 &Extensao = w &VersaoBase = 2014.02.25}.

trigger procedure for write of nfe002.
{shared.w}.
{nfe099.w}.
{bib00174.i}. /*Existeprograma*/
{bib00352.i}. /*getStatusNotaNfe002*/

def    var vi_seq          like nfe099.seq no-undo.
def    var vi_level        as int.
def    var vc_retorno      as char no-undo.
def    var ws-envia-sms    as logical.

def buffer nfe_est017_b for est017.

vc_retorno = return-value.

repeat.
    find first cfg000
      where cfg000.empresa = sh-empresa
        and cfg000.unidade = 00
        and cfg000.nome    = 'param-envia-sms'
      no-error.
      
    ws-envia-sms = false.
   
    if avail cfg000 then
       ws-envia-sms = (cfg000.conteudo = 'sim').

    if ws-envia-sms = yes then do:
    
       run executasms     in this-procedure. 
       
    end.
    
    /*Carlosj - sol 114628 -- 25/02/2014*/
    run executafin507e in this-procedure.

   vi_seq = 0.

   find last nfe099 no-lock
      where nfe099.empresa      = nfe002.empresa
        and nfe099.unidade      = nfe002.unidade
        and nfe099.tipo-ope     = nfe002.tipo-ope
        and nfe099.cgc-cpf-emit = nfe002.cgc-cpf-emit
        and nfe099.serie        = nfe002.serie
        and nfe099.numero-dcto  = nfe002.numero-dcto
        and nfe099.esp-dcto     = nfe002.esp-dcto
      no-error.
      
   if avail nfe099 then 
      vi_seq = nfe099.seq.

   release nfe099.

   vi_seq = vi_seq + 1.


   create nfe099.
   assign 
      nfe099.empresa      = nfe002.empresa
      nfe099.unidade      = nfe002.unidade
      nfe099.tipo-ope     = nfe002.tipo-ope
      nfe099.cgc-cpf-emit = nfe002.cgc-cpf-emit
      nfe099.serie        = nfe002.serie
      nfe099.numero-dcto  = nfe002.numero-dcto
      nfe099.esp-dcto     = nfe002.esp-dcto     
      nfe099.seq          = vi_seq
      .
   assign 
      nfe099.data-mvto     = nfe002.data-mvto
      nfe099.hora-mvto     = nfe002.hora-mvto
      nfe099.usuario       = nfe002.usuario
      nfe099.chave         = nfe002.chave
      nfe099.chave-conting = nfe002.chave-conting
      nfe099.numero-protoc = nfe002.numero-protoc
      nfe099.data-recebime = nfe002.data-recebime
      nfe099.hora-recebime = nfe002.hora-recebime
      nfe099.numero-reg-dp = nfe002.numero-reg-dp    
      nfe099.data-reg-dpec = nfe002.data-reg-dpec
      nfe099.hora-reg-dpec = nfe002.hora-reg-dpec
      nfe099.codigo-retorn = nfe002.codigo-retorno
      nfe099.msgDefaultErr = nfe002.msgDefaultErro
      nfe099.comunicador   = nfe002.comunicador
      .
   assign 
      nfe099.evento           = vc_nfe099-evento-CREATE
      nfe099.evento-usuario   = userid(ldbname(1))
      nfe099.evento-data-mvto = today
      nfe099.evento-hora-mvto = time
      .

   vi_level = 1.
   repeat while program-name(vi_level) <> ?.
      assign 
         nfe099.programa = nfe099.programa
                                     + 'program-name('
                                     + String(vi_level)
                                     + ') = '
                                     + PROGRAM-NAME(vi_level)
                                     + ';' + chr(10).

      vi_level = vi_level + 1.
   end.
   
   leave.
   
end.

return vc_retorno.

procedure executafin507e.

def var vl_acao as log.

if ExistePrograma("fin507e.p") then do.
   find first nfe_est017_b no-lock  of nfe002 no-error.
   if avail nfe_est017_b then do.
      vl_acao = getStatusNotaNfe002(buffer nfe_est017_b, 
                             buffer nfe002) ne 'AUTORIZADA'.
                             
       run fin507e.p 
         (buffer nfe_est017_b,
          input nfe002.codigo-retorno + " - " + nfe002.msgDefaultErro,
          input vl_acao).
       
       readkey pause 0.
       
   end.
end.
end procedure.              

procedure executasms.
   IF program-name(5) begins 'consultaNotaEdoc' then .
   else 
   DO:
     find first nfe_est017_b no-lock  of nfe002 no-error.
     if avail nfe_est017_b and 
        (getStatusNotaNfe002(buffer nfe_est017_b,
                            buffer nfe002) = 'AUTORIZADA' or 
         getStatusNotaNfe002(buffer nfe_est017_b,
                            buffer nfe002) = 'CANCELADA') then do:                        
        if avail nfe_est017_b and 
           nfe_est017_b.cancelado = false and 
           length(nfe_est017_b.cgc-cpf-parceiro) = 11 then 
           do.
              if getStatusNotaNfe002(buffer nfe_est017_b,
                                     buffer nfe002) = 'AUTORIZADA' and 
                  ExistePrograma("sms500.p") then
                  do:
                    run sms500.p (buffer nfe_est017_b).
                  end.                    
           end. 
      
        if avail nfe_est017_b and 
           nfe_est017_b.cancelado = yes and 
           length(nfe_est017_b.cgc-cpf-parceiro) = 11 then 
           do.
              if getStatusNotaNfe002(buffer nfe_est017_b,
                                     buffer nfe002) = 'CANCELADA' and 
                 ExistePrograma("sms500a.p") then
                 do:
                    run sms500a.p (buffer nfe_est017_b).
                 end.                    
           end. 
     end.      
   end.
end procedure.

&Endif
