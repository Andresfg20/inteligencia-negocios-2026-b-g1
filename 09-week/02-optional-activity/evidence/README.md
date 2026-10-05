# Movies Dataset – Mini-ETL & First Measures (Corte 2)

Business Intelligence · Graded activity – Power BI, Power Query and DAX.

**Dataset:** `movies.csv` (Kaggle – Movies Dataset for Feature Extraction & Prediction), 9,999 raw rows and 9 columns.

## Repository contents

| File | Description |
|------|-------------|
| `movies.csv` | Raw dataset |
| `movies_etl.pq` | Power Query (M) script with the 4 cleaning steps (edit the file path in the `Source` step) |
| `measures.dax` | The 3 DAX measures |
| `movies.pbix` | Power BI report |
| `evidence/power_query_steps.png` | Applied Steps panel up to the last step, `Paso4_CategoriaDuracion` |
| `evidence/measures.png` | The three measures in Power BI |
| `evidence/filter_context_before.png` | Card with no filters (global average rating) |
| `evidence/filter_context_after.png` | Same card with the `CATEGORIA_DURACION` slicer set to "Larga" |

## ETL steps & measures

The raw `movies.csv` file was loaded into Power Query (query named `movies`) and cleaned in four documented steps. First, I removed invisible characters and line breaks (`\n`) from the `GENRE` and `STARS` columns by applying `Text.Clean` and `Text.Trim`, so each value became a single tidy line of text. Second, I removed duplicate rows with `Table.Distinct`, running this step after the text cleanup so that rows differing only by whitespace or line breaks were also detected as duplicates; this reduced the table from 9,999 to 9,568 rows. Third, I cleaned and converted the numeric columns: in `VOTES` I stripped the thousands separators (commas) and spaces and cast the column to whole numbers, and in `Gross` I removed the `$` and `M` symbols and the commas, converted the result to a decimal number, and multiplied it by 1,000,000 to create a `GROSS_USD` column in full dollars, treating empty values and `"NaN"` text as nulls and using the en-US culture to avoid decimal-separator errors. Fourth, I created a conditional column, `CATEGORIA_DURACION`, based on `RunTime`, which labels each movie as "Larga" when it lasts 120 minutes or more, "Estándar" otherwise, and "Sin dato" when the runtime is missing.

After loading the cleaned table into the model, I created three DAX measures. `Total Votos = SUM(movies[VOTES])` uses `SUM` to return the total number of votes, and `Calificación Promedio = AVERAGE(movies[RATING])` uses `AVERAGE` to return the mean rating. `Recaudación Promedio por Voto` is a derived measure that uses `DIVIDE` to divide `SUM(movies[GROSS_USD])` by the votes of only those movies that have a recorded gross, so numerator and denominator refer to the same rows, and `DIVIDE` returns a blank instead of an error when the denominator is zero. Because these are measures rather than static columns, they are re-evaluated whenever the filter context changes, so a card showing `Calificación Promedio` updates automatically when a slicer or a chart axis such as `GENRE` or `CATEGORIA_DURACION` is selected.

```dax
Total Votos = SUM ( movies[VOTES] )

Calificación Promedio = AVERAGE ( movies[RATING] )

Recaudación Promedio por Voto =
DIVIDE (
    SUM ( movies[GROSS_USD] ),
    CALCULATE ( SUM ( movies[VOTES] ), NOT ISBLANK ( movies[GROSS_USD] ) )
)
```

## Filter context

With no filters applied, the card evaluates `Calificación Promedio` over the entire `movies` table and shows the global average rating (6.92). When the `CATEGORIA_DURACION` slicer is set to "Larga", Power BI filters the table first and then recalculates `AVERAGE(movies[RATING])` using only the matching rows, so the same card shows 6.84 without any change to the DAX code. The measure is not a stored value: it is evaluated again for every filter context, whether it comes from a slicer, a page filter, or a chart axis such as `GENRE`.

## Data quality notes

- About 95% of the rows have no `Gross` value (only 460 of 9,568 rows after removing duplicates), so `Recaudación Promedio por Voto` is based on a small subset of movies.
- About 30% of the rows have no `RunTime`, so many movies fall into the "Sin dato" category.
- `GENRE` holds combined values such as "Action, Drama", so each combination appears as its own category in visuals.
