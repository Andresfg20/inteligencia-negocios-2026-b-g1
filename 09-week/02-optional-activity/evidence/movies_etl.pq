// movies_etl.pq  -  Mini-ETL (Corte 2)
// =====================================================================
let
    // ---- Carga ------------------------------------------------------
    Source = Csv.Document(
        File.Contents("C:\Users\Usuario\Downloads\evidence\movies.csv"),
        [Delimiter = ",", Encoding = 65001, QuoteStyle = QuoteStyle.Csv]
    ),
    Promoted = Table.PromoteHeaders(Source, [PromoteAllScalars = true]),

    // ---- PASO 1: Limpiar caracteres invisibles y saltos de linea ----
    Paso1_LimpiarTexto = Table.TransformColumns(
        Promoted,
        {
            {"GENRE", each if _ = null then null else Text.Trim(Text.Clean(_)), type text},
            {"STARS", each if _ = null then null else Text.Trim(Text.Clean(_)), type text}
        }
    ),

    // ---- PASO 2: Eliminar filas duplicadas --------------------------
    Paso2_QuitarDuplicados = Table.Distinct(Paso1_LimpiarTexto),

    // ---- PASO 3: Limpiar y convertir VOTES y Gross ------------------
    // 3a) Quitar comas, espacios, "$" y "M" (todavia como texto)
    Paso3a_LimpiarNumericos = Table.TransformColumns(
        Paso2_QuitarDuplicados,
        {
            {"VOTES",
                each if _ = null then null
                     else let t = Text.Replace(Text.Replace(Text.Trim(_), ",", ""), " ", "")
                          in if t = "" or t = "NaN" then null else t,
                type text},
            {"Gross",
                each if _ = null then null
                     else let t = Text.Replace(Text.Replace(Text.Replace(Text.Replace(
                                    Text.Trim(_), "$", ""), "M", ""), ",", ""), " ", "")
                          in if t = "" or t = "NaN" then null else t,
                type text}
        }
    ),
    // 3b) Convertir a numerico de forma segura evitando errores por filas corrompidas
    Paso3b_Tipos = Table.TransformColumnTypes(
        Paso3a_LimpiarNumericos,
        {
            {"VOTES", Int64.Type},
            {"Gross", type number},
            {"RATING", type number},
            {"RunTime", type number}
        },
        "en-US"
    ),
    // 3c) Gross viene en millones ("75.47M"): se pasa a dolares completos
    Paso3c_GrossUSD = Table.AddColumn(
        Paso3b_Tipos, "GROSS_USD",
        each if [Gross] = null then null else [Gross] * 1000000,
        type number
    ),

    // ---- PASO 4: Columna condicional basada en RunTime --------------
    Paso4_CategoriaDuracion = Table.AddColumn(
        Paso3c_GrossUSD, "CATEGORIA_DURACION",
        each if [RunTime] = null then "Sin dato"
             else if [RunTime] >= 120 then "Larga"
             else "Estándar",
        type text
    )
in
    Paso4_CategoriaDuracion