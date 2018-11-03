      *------------------------------------------------------------------------
      * PROGRAMA.: RPSRVCONF
      * AUTOR....: Personalsoft S.A.S. - Wilson David Calderón
      * FECHA....: 2018-08-27
      * DESCRIP..: Consultar parametrización
      *------------------------------------------------------------------------
      * COMPILA..:
      *
      *  - Se crea el módulo
      *
      *    CRTSQLRPGI OBJ(FPOEXTPG/RPSRVCONF) SRCFILE(FPOEXTPG/QRPGLESRC)
      *                 COMMIT(*NONE) OBJTYPE(*MODULE)
      *                 CLOSQLCSR(*ENDMOD) REPLACE(*YES)
      *                 DBGVIEW(*SOURCE)
      *
      *  - Se crea el programa
      *
      *    CRTPGM     PGM(FPOEXTPG/RPSRVCONF)
      *               MODULE(FPOEXTPG/RPSRVCONF)
      *               ACTGRP(*CALLER)
      *
      *------------------------------------------------------------------------
      * AAAA-MM-DD  Autor
      * Descripción del cambio
      *------------------------------------------------------------------------

     **Free

       //- Estructuras de datos------------------------------------------------

       dcl-Ds Ds_tmData ExtName('FPOEXTDA/BYP_CONARC')
              Qualified Template end-Ds;

       dcl-Ds Ds_tmParametros Qualified Template;
         Registros Int(5);
         Datos LikeDs(Ds_tmData) Dim(100);
       end-Ds Ds_tmParametros;

       dcl-Ds Ds_tmFiltro Qualified Template;
         Llave Char(6);
         Codigo Char(3);
       end-Ds Ds_tmFiltro;

       //- Parámetros ---------------------------------------------------------

       //Prototipo
       dcl-Pr Parametros ExtPgm('RPSRVCONF');
         par_Parametros LikeDs(Ds_tmParametros);
         par_Llave Char(6) Const;
         par_Codigo Char(3) Const Options(*nopass);
       end-Pr;

       //Interfaz
       dcl-Pi Parametros;
         p_Parametros LikeDs(Ds_tmParametros);
         p_Llave Char(6) Const;
         p_Codigo Char(3) Const Options(*nopass);
       end-Pi;

       //- Bloque principal ---------------------------------------------------

       If %Parms >= %ParmNum(p_Codigo);
         Pr_ObtenerParametros(p_parametros:p_Llave:p_Codigo);
       Else;
         Pr_ObtenerParametros(p_parametros:p_Llave);
       EndIf;

       Return;

       //----------------------------------------------------------------------

       //----------------------------------------------------------------------
       // Nombre Proc.: Pr_ObtenerParametros
       // Propósito...: Obtener datos parametrizados
       // Parámetros..: Parametrización
       //               Llave
       //               Código de la llave
       //----------------------------------------------------------------------
       dcl-Proc Pr_ObtenerParametros Export;
         dcl-Pi *n;
           p_Parameters LikeDs(Ds_tmParametros);
           p_Key Char(6) Const;
           p_Cod Char(3) Const Options(*nopass);
         end-Pi;

         //- Estructuras de datos----------------------------------------------

         dcl-Ds Ds_Parameters LikeDs(Ds_tmParametros);

         //- Variables --------------------------------------------------------

         dcl-s w_SQL Varchar(100);

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Parameters;
         Clear w_SQL;

         If %Parms >= %ParmNum(p_Cod);
           w_SQL = Fn_ObtenerSQL(p_Key:p_Cod);
           Ds_Parameters = Fn_ExecSQL(w_SQL:p_Key:p_Cod);
         Else;
           w_SQL = Fn_ObtenerSQL(p_Key);
           Ds_Parameters = Fn_ExecSQL(w_SQL:p_Key);
         EndIf;

         p_Parameters = Ds_Parameters;

       end-Proc Pr_ObtenerParametros;

       //----------------------------------------------------------------------
       //Nombre Func.: Fn_ObtenerSQL
       //Propósito...: Obtener la sentencia SQL
       //Parámetros..: Llave
       //              Código de llave
       //Retorna.....: Sentencia SQL
       //----------------------------------------------------------------------
       dcl-Proc Fn_ObtenerSQL;
         dcl-Pi *n Varchar(100);
           p_Campo1 Char(6) Const;
           p_Campo2 Char(3) Const Options(*nopass);
         end-Pi;

         //- Variables --------------------------------------------------------

         dcl-s w_String Varchar(100);
         dcl-s w_Select Varchar(100);
         dcl-s w_From Like(w_Select);
         dcl-s w_Where Like(w_Select);

         //- Lógica del procedimiento -----------------------------------------

         Clear w_String;
         Clear w_Select;
         Clear w_From;
         Clear w_Where;

         w_Select = 'Select * ';
         w_From   = 'From FPOEXTDA/BYP_CONARC ';
         w_Where  = 'Where CONIDE = ? ';

         If %Parms >= %ParmNum(p_Campo2);
           w_Where = w_Where + 'And CONID1 = ? ';
         EndIf;

         w_String = w_Select + w_From + w_Where;

         Return w_String;

       end-Proc Fn_ObtenerSQL;

       //----------------------------------------------------------------------
       //Nombre Func.: Fn_ExecSQL
       //Propósito...: Consultar la información de la parametrización
       //Parámetros..: Sentencia SQL
       //              Llave
       //              Código de llave
       //Retorna.....: Registros
       //              Parametrización
       //----------------------------------------------------------------------
       dcl-Proc Fn_ExecSQL;
         dcl-Pi *n LikeDs(Ds_tmParametros);
           p_Sentencia Varchar(100) Const;
           p_CONIDE Char(6) Const;
           p_CONID1 Char(3) Const Options(*nopass);
         end-Pi;

         //- Estructuras de datos ---------------------------------------------

         dcl-Ds Ds_Respuesta LikeDs(Ds_tmData) Dim(100);
         dcl-Ds Ds_Query LikeDs(Ds_tmParametros);

         //- Variables --------------------------------------------------------

         dcl-s w_Sentencia Varchar(100);
         dcl-s w_Rows Int(5);

         //- Lógica del procedimiento -----------------------------------------

         Clear Ds_Respuesta;
         Clear Ds_Query;
         Clear w_Rows;
         Clear w_Sentencia;

         w_Sentencia = p_Sentencia;

         Exec SQL PREPARE SQL_PAR FROM :w_Sentencia;

         Exec SQL DECLARE CUR_PAR CURSOR FOR SQL_PAR;

         If %Parms >= %ParmNum(p_CONID1);
           Exec SQL OPEN CUR_PAR USING :p_CONIDE, :p_CONID1;
         Else;
           Exec SQL OPEN CUR_PAR USING :p_CONIDE;
         EndIf;

         Exec SQL FETCH FROM CUR_PAR FOR 100 ROWS INTO :Ds_Respuesta;

         Exec SQL GET DIAGNOSTICS :w_Rows = ROW_COUNT;

         Ds_Query.Registros = w_Rows;
         Ds_Query.Datos = Ds_Respuesta;

         Exec SQL CLOSE CUR_PAR;

         Return Ds_Query;

       end-Proc Fn_ExecSQL;
