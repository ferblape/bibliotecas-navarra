# Wrapper del catálogo de las Bibliotecas Públicas de Navarra

## Objetivo

Una web sencilla para buscar libros en el catálogo de las Bibliotecas Públicas de Navarra, filtrar por biblioteca y ver si hay ejemplares disponibles, sin pelearse con el OPAC oficial.

No es un servicio oficial. Cada búsqueda consulta el OPAC en vivo; no copiamos el catálogo.

## Cómo funciona el OPAC (investigado el 2026-11-15)

- AbsysNet OPAC (Baratz). CGI `https://www.navarra.es/opac/abnetcl.exe`, HTML en ISO-8859-1. Sin API JSON, sin SRU, Z39.50 (puerto 210) cerrado.
- Sesión:
  1. `GET /opac/abnetcl.exe?ACC=101` devuelve un meta-refresh a `/opac/abnetcl.exe/<token>?ACC=101` y las cookies `GN` y `GNW`.
  2. La sesión caduca a los ~5 minutos.
- Biblioteca: POST al `action` del formulario `subform` con `ACC=101&xindbt=&subcat=<código>`. Queda guardada en la sesión. Códigos en el `<select name="subcat">` (p. ej. `BPN/BP21` = Pamplona-San Pedro).
- Búsqueda: POST al `action` del formulario `abnformSearch` con `ACC=131&START=1&FORM=1&xindbt=&xmismo=on&FORM_DIGITAL=9&xsface=on&xsqf01=<términos>`.
- Resultados: `ol.c-docs > li.c-docs_unit`. Clases `c-docs_author`, `c-docs_title`, `c-docs_titleRest`, `c-docs_data` (editorial, ISBN). Bloque oculto `p.c-docs_marc` con spans `js-TITN` (ID del registro), `js-T020a` (ISBN), `js-FEPU` (año), `js-LENG` (idioma), `js-ld06`/`js-ld07` (tipo de material). Contador "N / M de T" en `p.c-paginator_count`.
- Ficha: enlace `ACC=165&DOC=n` de la lista. Ejemplares con biblioteca, sucursal, localización, estado, signatura, soporte y disponibilidad.
- Enlace permanente sin sesión: `https://www.navarra.es/opac/abnetcl.exe?TITN=<id>`.
- `robots.txt` de navarra.es no bloquea `/opac`.

## Alcance de la primera versión

- Buscar por texto libre.
- Filtrar por biblioteca; la elección se recuerda en una cookie.
- Lista de resultados con portada, autor, título, editorial, año e ISBN.
- Ficha con ejemplares y disponibilidad por biblioteca.
- Enlace a la ficha oficial (`?TITN=`).
- Fuera: login, préstamos, reservas, índice propio del catálogo.

## Diseño

- Rails 8.1, Ruby 4.0, SQLite (solo para Solid Cache), Minitest, Propshaft, Importmap.
- `Opac::Session`: abre sesión, guarda token y cookies, hace GET/POST en ISO-8859-1.
- `Opac::ResultsPage` y `Opac::RecordPage`: parsean HTML con Nokogiri y devuelven objetos `Data` (`Record`, `Copy`).
- `Catalog`: la fachada que usa la app. `Catalog.search(query, library:, page:)` y `Catalog.record(id, library:)`. Cachea respuestas unos minutos con `Rails.cache`.
- La lista de bibliotecas se lee del `<select>` del OPAC y se cachea un día.
- Controladores `SearchesController` y `RecordsController`. HTML con Turbo; sin JS propio salvo que haga falta.

## Buen uso del OPAC

- Caché de búsquedas y fichas.
- Límite de peticiones por IP en la app (`rate_limit` de Rails).
- User-Agent propio que identifica la herramienta.
- Pie con la fuente de los datos, aviso de que no es un servicio oficial y enlace al OPAC.

## Tests

- Parsers: fixtures con HTML real descargado del OPAC (`test/fixtures/files/opac/`).
- `Opac::Session` y `Catalog`: tests de integración contra el OPAC real, marcados para poder saltarlos sin red (`OPAC_LIVE=1`).
- Controladores y sistema: con fixtures HTML servidas por un `Catalog` de test que lee de disco.

## Pendiente

- Leer el aviso legal de navarra.es antes de difundir.
- Escribir al Servicio de Bibliotecas Públicas de Navarra: avisar de la herramienta y preguntar por API o export.
