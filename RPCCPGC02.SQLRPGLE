      *------------------------------------------------------------------------
      * PROGRAMA...: RPCCPGC02
      * AUTOR......: Personalsoft S.A.S. - Wilson David Calderón
      * FECHA......: 2018-09-03
      * DESCRIPCION: Consultar gestión de colas CCP
      *------------------------------------------------------------------------
      *COMPILACION:
      *------------------------------------------------------------------------

     **Free

       //- Prototipos ---------------------------------------------------------

       //- Procedimiento de 'RPSRVCONF'
       dcl-Pr Pr_ObtenerParametros;
         par_Configuracion LikeDs(Ds_tmConfiguracion);
         par_Codigo Char(6) Const;
         par_Subcodigo Char(3) Const Options(*nopass);
       end-Pr;

       //- Estructuras de datos -----------------------------------------------

       dcl-Ds Ds_tmQuery ExtName('FPOEXTDA/CCPQUEUE') Qualified Template end-Ds;
       dcl-Ds Ds_tmCnf ExtName('FPOEXTDA/BYP_CONARC') Qualified Template end-Ds;

       dcl-Ds Ds_tmConfiguracion Qualified Template;
         Registros Int(5);
         Datos LikeDs(Ds_tmCnf) Dim(100);
       end-Ds Ds_tmConfiguracion;

       dcl-Ds Ds_tmEntrada Qualified Template;
         Tipo Char(3);
         Numero Char(16);
         Linea Char(1);
       end-Ds Ds_tmEntrada;

       dcl-Ds Ds_tmSalida Qualified Template;
         Codigo Char(2);
         Mensaje Char(200);
       end-Ds Ds_tmSalida;

       dcl-Ds Ds_tmParametros Qualified Template;
         Entrada LikeDs(Ds_tmEntrada);
         Salida LikeDs(Ds_tmSalida);
       end-Ds Ds_tmParametros;

       dcl-Ds Ds_tmRespuesta Qualified Template;
         Registros Int(3);
         Datos LikeDs(Ds_tmQuery) Dim(4);
       end-Ds Ds_tmRespuesta;

       dcl-Ds Ds_Prms LikeDs(Ds_tmParametros);

       //- Constantes ---------------------------------------------------------

       dcl-c OK_EXITO '00';
       dcl-c ER_TIPO '01';
       dcl-c ER_NUMERO '02';
       dcl-c ER_LINEA '03';
       dcl-c ESENCIAL 'ESE';
       dcl-c TIPO_ID 'CCPTID';
       dcl-c LINEA 'CCPLIN';

       //- Parámetros ---------------------------------------------------------

       //Prototipo
       dcl-pr Parametros ExtPgm('RPCCPGC02');
         par_Tipo Char(3) Const;
         par_Numero Char(16) Const;
         par_Linea Char(1) Const;
         par_Codigo Char(2);
         par_Mensaje Char(200);
       end-pr;

       //Interfaz
       dcl-pi Parametros;
         p_Tipo Char(3) Const;
         p_Numero Char(16) Const;
         p_Linea Char(1) Const;
         p_Codigo Char(2);
         p_Mensaje Char(200);
       end-pi;

       //- Bloque principal ---------------------------------------------------

       Pr_RecibirParametros();

       Pr_ConsultarInformacion(Ds_Prms);

       Pr_RetornarParametros();

       *InLr = *On;

       //----------------------------------------------------------------------

       //----------------------------------------------------------------------
       //Nombre Proc.: Pr_RecibirParametros
       //Propósito...: Recibir parámetros de entrada
       //Parámetros..: Tipo Documento
       //              Numero Documento
       //              Línea de negocio
       //----------------------------------------------------------------------
       dcl-Proc Pr_RecibirParametros;

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Prms;

         Ds_Prms.Entrada.Tipo = p_Tipo;
         Ds_Prms.Entrada.Numero = p_Numero;
         Ds_Prms.Entrada.Linea = p_Linea;

       end-Proc Pr_RecibirParametros;

       //----------------------------------------------------------------------
       //Nombre Proc.: Pr_RetornarParametros
       //Propósito...: Retornar parámetros de salida
       //Parámetros..: Codigo
       //              Mensaje
       //----------------------------------------------------------------------
       dcl-Proc Pr_RetornarParametros;

         //- Lógica del procedimiento -----------------------------------------

         p_Codigo = Ds_Prms.Salida.Codigo;
         p_Mensaje = Ds_Prms.Salida.Mensaje;

       end-Proc Pr_RetornarParametros;

       //----------------------------------------------------------------------
       //Nombre Proc.: Pr_ConsultarInformacion
       //Propósito...: Obtener información del afiliado
       //Parámetros..: Entrada
       //                Tipo Documento
       //                Numero Documento
       //              Salida
       //                Código de error
       //                Descripción
       //----------------------------------------------------------------------
       dcl-Proc Pr_ConsultarInformacion;
         dcl-Pi *n;
           p_Data LikeDs(Ds_tmParametros);
         end-Pi;

         //- Estructuras de datos ---------------------------------------------

         dcl-Ds Ds_Data LikeDs(Ds_tmParametros);
         dcl-Ds Ds_Respuesta LikeDs(Ds_tmRespuesta);

         //- Variables --------------------------------------------------------

         dcl-s w_SQL Varchar(300);

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Data;
         Clear w_SQL;

         Ds_Data = p_Data;

         Pr_ValidarParametros(Ds_Data);

         If Ds_Data.Salida.Codigo <> OK_EXITO;
           p_Data = Ds_Data;
           Return;
         EndIf;

         w_SQL = Fn_ObtenerSQL(Ds_Data.Entrada);

         Ds_Respuesta = Fn_ConsultarCursor(Ds_Data.Entrada:w_SQL);

         Pr_RetornarResultSet(Ds_Respuesta);

         p_Data = Ds_Data;

       end-Proc Pr_ConsultarInformacion;

       //----------------------------------------------------------------------
       //Nombre Proc.: Pr_ValidarParametros
       //Propósito...: Valida los parámetros de entrada
       //Parámetros..: Entrada
       //                Tipo Documento
       //                Numero Documento
       //                Línea
       //              Salida
       //                Código
       //                Mensaje
       //----------------------------------------------------------------------
       dcl-Proc Pr_ValidarParametros;
         dcl-Pi *n;
           p_Datos LikeDs(Ds_tmParametros);
         end-Pi;

         //- Estructuras de datos ---------------------------------------------

         dcl-Ds Ds_Datos LikeDs(Ds_tmParametros);
         dcl-Ds Ds_TipoId LikeDs(Ds_tmConfiguracion);
         dcl-Ds Ds_Linea LikeDs(Ds_tmConfiguracion);

         //- Variables --------------------------------------------------------

         dcl-s w_Identificacion Zoned(16);
         dcl-s w_Codigo Char(6);
         dcl-s w_Pos Int(5);
         dcl-s Ind_Ide Ind;

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Datos;
         Clear Ds_TipoId;
         Clear Ds_Linea;
         Clear w_Identificacion;
         Clear w_Codigo;
         Clear Ind_Ide;

         Ds_Datos = p_Datos;

         w_Codigo = TIPO_ID;
         Pr_ObtenerParametros(Ds_TipoId:w_Codigo);

         w_Codigo = LINEA;
         Pr_ObtenerParametros(Ds_Linea:w_Codigo);

         Clear w_Pos;
         If Ds_TipoId.Registros > *Zeros;
           w_Pos = %LookUp(Ds_Datos.Entrada.Tipo:Ds_TipoId.Datos(*).CONID1:
                           1:Ds_TipoId.Registros);
         EndIf;

         If w_Pos = *Zeros;
           Ds_Datos.Salida.Codigo = ER_TIPO;
           Ds_Datos.Salida.Mensaje = 'Tipo de identificación incorrecta';
           p_Datos = Ds_Datos;
           Return;
         EndIf;

         Monitor;
           w_Identificacion = %Int(Ds_Datos.Entrada.Numero);
         On-Error;
           Ind_Ide = *On;
         EndMon;

         If w_Identificacion = *Zeros Or Ind_Ide;
           Ds_Datos.Salida.Codigo = ER_NUMERO;
           Ds_Datos.Salida.Mensaje = 'Número de Identificación incorrecta';
           p_Datos = Ds_Datos;
           Return;
         EndIf;

         If Ds_Datos.Entrada.Linea <> *Blanks;

           Clear w_Pos;
           If Ds_Linea.Registros > *Zeros;
             w_Pos = %LookUp(Ds_Datos.Entrada.Linea:Ds_Linea.Datos(*).CONID1:
                             1:Ds_Linea.Registros);
           EndIf;

           If w_Pos = *Zeros;
             Ds_Datos.Salida.Codigo = ER_LINEA;
             Ds_Datos.Salida.Mensaje = 'Línea de negocio incorrecta';
             p_Datos = Ds_Datos;
             Return;
           EndIf;

         EndIf;

         Ds_Datos.Salida.Codigo = OK_EXITO;

         p_Datos = Ds_Datos;

       end-Proc Pr_ValidarParametros;

       //----------------------------------------------------------------------
       //Nombre Func.: Fn_ObtenerSQL
       //Propósito...: Obtener la sentencia SQL
       //Parámetros..: Tipo
       //              Número
       //              Línea
       //Retorna.....: Sentencia SQL
       //----------------------------------------------------------------------
       dcl-Proc Fn_ObtenerSQL;
         dcl-Pi *n Varchar(300);
           p_Info LikeDs(Ds_tmEntrada) Const;
         end-Pi;

         //- Estructuras de datos ---------------------------------------------

         dcl-Ds Ds_Info LikeDs(Ds_tmEntrada);

         //- Variables --------------------------------------------------------

         dcl-s w_String Varchar(300);
         dcl-s w_Select Varchar(100);
         dcl-s w_From Like(w_Select);
         dcl-s w_Where Like(w_Select);

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Info;
         Clear w_String;
         Clear w_Select;
         Clear w_From;
         Clear w_Where;

         Ds_Info = p_Info;

         w_Select = 'Select * ';
         w_From = 'From FPOEXTDA/CCPQUEUE ';

         w_Where = 'Where CCPTID = ? And CCPIDE = ? ';

         If Ds_Info.Linea <> *Blanks;
           w_Where = %Trim(w_Where) + ' And CCPLIN = ? ';
         EndIf;

         w_String = w_Select + w_From + w_Where;

         Return w_String;

       end-Proc Fn_ObtenerSQL;

       //----------------------------------------------------------------------
       //Nombre Func.: Fn_ConsultarCursor
       //Propósito...: Consultar la información CCP
       //Parámetros..: Tipo
       //              Número
       //              Línea
       //              Consulta SQL
       //Retorna.....: Registros
       //              CCP
       //----------------------------------------------------------------------
       dcl-Proc Fn_ConsultarCursor;
         dcl-Pi *n LikeDs(Ds_tmRespuesta);
           p_Filtro LikeDs(Ds_tmEntrada) Const;
           p_Sentencia Varchar(300) Const;
         end-Pi;

         //- Estructuras de datos ---------------------------------------------

         dcl-Ds Ds_Filtro LikeDs(Ds_tmEntrada);
         dcl-Ds Ds_CCP LikeDs(Ds_tmRespuesta);
         dcl-Ds Ds_Registro LikeDs(Ds_tmQuery) Dim(4);

         //- Variables --------------------------------------------------------

         dcl-s w_Sentencia Varchar(300);
         dcl-s w_Numero Zoned(16);
         dcl-s w_Rows Int(5);

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Filtro;
         Clear Ds_CCP;
         Clear Ds_Registro;
         Clear w_Sentencia;
         Clear w_Rows;

         Ds_Filtro = p_Filtro;
         w_Sentencia = p_Sentencia;
         w_Numero = %Int(Ds_Filtro.Numero);

         Exec SQL PREPARE SQL_SEL FROM :w_Sentencia;

         Exec SQL DECLARE CUR_CCP CURSOR FOR SQL_SEL;

         If Ds_Filtro.Linea <> *Blanks;
           Exec SQL
             OPEN CUR_CCP USING :Ds_Filtro.Tipo,
                                :w_Numero,
                                :Ds_Filtro.Linea;
         Else;
           Exec SQL
             OPEN CUR_CCP USING :Ds_Filtro.Tipo,
                                :w_Numero;
         EndIf;

         Exec SQL FETCH FROM CUR_CCP FOR 4 ROWS INTO :Ds_Registro;

         If SQLCOD <> *Zeros;

           Ds_Registro(1).CCPTID = Ds_Filtro.Tipo;
           Ds_Registro(1).CCPIDE = w_Numero;
           Ds_Registro(1).CCPASR = ESENCIAL;
           Ds_Registro(1).CCPASA = ESENCIAL;
           Ds_Registro(1).CCPLIN = Ds_Filtro.Linea;

           Ds_CCP.Registros = 1;
           Ds_CCP.Datos = Ds_Registro;

         Else;

           Exec SQL GET DIAGNOSTICS :w_Rows = ROW_COUNT;

           Ds_CCP.Registros = w_Rows;
           Ds_CCP.Datos = Ds_Registro;

         EndIf;

         Exec SQL CLOSE CUR_CCP;

         Return Ds_CCP;

       end-Proc Fn_ConsultarCursor;

       //----------------------------------------------------------------------
       //Nombre Proc.: Pr_RetornarResultSet
       //Propósito...: Retornar la información del Afiliado
       //Parámetros..: Datos de consulta
       //----------------------------------------------------------------------
       dcl-Proc Pr_RetornarResultSet;
         dcl-Pi *n;
           p_Respond LikeDs(Ds_tmRespuesta);
         end-Pi;

         dcl-Ds Ds_Respond LikeDs(Ds_tmRespuesta);
         dcl-Ds Ds_Array LikeDs(Ds_tmQuery) Dim(4);

         //- Variables --------------------------------------------------------

         dcl-s w_Reg Int(3);

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Respond;
         Clear Ds_Array;
         Clear w_Reg;

         Ds_Respond = p_Respond;

         Ds_Array = Ds_Respond.Datos;
         w_Reg = Ds_Respond.Registros;

         Exec SQL
           SET RESULT SETS FOR RETURN TO CLIENT
            Array :Ds_Array For :w_Reg Rows;

       end-Proc Pr_RetornarResultSet;
