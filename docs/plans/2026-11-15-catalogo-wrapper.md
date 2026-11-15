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
- Paginación: `GET <sesión>?ACC=161&DOC=<n>` (n = primer registro de la página, 10 por página) en la misma sesión de la búsqueda.
- Ficha: `GET /opac/abnetcl.exe?TITN=<id>` devuelve un meta-refresh a una sesión nueva con la ficha completa, con los ejemplares de todas las bibliotecas (`div.copias_data`, `h3#copias_bib<código>`, `table[data-bidesc][data-sudesc]`, `tr[data-disp]`). No depende de la sesión de búsqueda; el filtro por biblioteca se hace en Ruby. Ese mismo enlace es el enlace permanente a la ficha oficial.
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
- `Opac::ResultsPage`, `Opac::RecordPage` y `Opac::LibrariesPage`: parsean HTML con Nokogiri y devuelven objetos `Data` (`Results`, `Record`, `Copy`, `Library`). Los campos salen del bloque MARC oculto (`Opac::MarcFields`).
- `Catalog`: la fachada que usa la app. `Catalog.search(query, library:, page:)` y `Catalog.record(id)`; la vista filtra los ejemplares con `Library#copies_code`. Cachea respuestas unos minutos con `Rails.cache`.
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
- Integración (`test/integration/catalog_search_test.rb`): los criterios de aceptación van contra el OPAC real con `OPAC_LIVE=1`, sin `Catalog` falso (nada de mocks en end-to-end). "No disponible" y `rate_limit` corren siempre, con `Opac::Session.host` en `localhost`.
- En test la caché es `:memory_store` para que los tests en vivo reutilicen respuestas y abran menos sesiones. Lanzar la suite en vivo una sola vez seguida: el OPAC rechaza sesiones ("Error 205") si se abren demasiadas.

## Estado (2026-11-15)

Hecho:
- App Rails generada (Ruby 4.0.9, Rails 8.1.3; sin mailer, mailbox, action text, active storage, cable, jobs ni kamal).
- Parsers en `app/models/opac/` con tests sobre HTML real (`test/fixtures/files/opac/`). `bin/rails test` y `bin/rubocop` en verde.
- `Opac::Session` (`app/models/opac/session.rb`): `Opac::Session.open(ACC: 101)` o `open(TITN: id)` sigue el meta-refresh y deja la página de llegada en `#page`; `#get`/`#post` sobre la ruta de sesión, en UTF-8. El POST va a la ruta de sesión sin el `/NT1` del `action` y funciona igual. Tests en vivo con `OPAC_LIVE=1 bin/rails test test/models/opac/session_test.rb`. Los caracteres que no existen en ISO-8859-1 se quitan al enviar.
- `Catalog` (`app/models/catalog.rb`): `search(query, field:, library:, page:)` y `record(id)` cacheados 10 minutos, `libraries` un día. Los errores de red, timeouts y códigos HTTP de error del OPAC salen como `Catalog::Unavailable`. Los tests de errores y caché apuntan `Opac::Session.host` a `localhost` en lugar de usar mocks.
- Búsqueda por campo: Todo, Título, Autor o Materia, con el formulario avanzado del OPAC (`FORM=2`), que lleva la biblioteca (`subcat`) en el mismo POST. Un campo por búsqueda: con biblioteca elegida, el OPAC combina mal varios campos (título "patria" + autor "aramburu" en Biblioteca de Navarra devuelve libros de otros autores).
- Sesiones: `Opac::Session.open(...) { }` cierra la sesión con `ACC=301` al acabar. Sin cerrarlas, una pasada de los tests saturaba el OPAC ("Error 205"). Si la entrada no da sesión o la página no es la esperada, `Opac::Session::Refused` / `Opac::UnexpectedPage` y `Catalog::Unavailable`; no se cachean páginas de error como "0 resultados".
- Web: `SearchesController#index` (raíz, `?q=&field=&library=&page=`) y `RecordsController#show` (`/records/:id`). Biblioteca recordada en cookie permanente; en la ficha, sus ejemplares primero y abiertos, el resto por orden alfabético. Página de "catálogo no disponible" (503) y `rate_limit` de 30 peticiones por minuto y controlador (429). Pie con fuente de los datos y aviso de servicio no oficial. CSS propio con modo oscuro y móvil.
- Portadas de Open Library por ISBN; sin portada, Open Library devuelve un GIF transparente.
- Solid Queue fuera (sin jobs). Active Job sigue porque Solid Cache carga su `ExpiryJob`. Producción: `storage/production.sqlite3` y `storage/production_cache.sqlite3`.
- Listas de favoritos anónimas (`List`, `Bookmark`): sin cuentas; la URL `/listas/<token>` (token aleatorio de 24 caracteres, `has_secure_token`) es la llave, y quien la conoce puede verla y cambiarla. Una lista por navegador, recordada en la cookie `list`. Se crea con el primer "Guardar" y avisa de que hay que guardar su dirección. Abrir la URL de una lista ajena pide confirmación antes de cambiar la cookie; "Olvidar esta lista en este navegador" borra la cookie, no la lista. Cada favorito guarda título, autor e ISBN para pintar la lista sin consultar el OPAC. Las páginas de lista llevan `noindex`.

Siguiente (ideas, sin orden):
- Orden de resultados: el OPAC ordena por autor/título y en todo el catálogo salen primero folletos antiguos ("Patria" → página 1 sin la novela de Aramburu). `xssort` (fecha) no pareció cambiar nada; investigar.
- Si `Opac::Session.new` falla tras abrir la conexión HTTP, la conexión no se cierra hasta el GC.
- Las portadas del propio OPAC vienen de `covers.absys.cloud/<isbn>`; quizá cubren más que Open Library.

## Pendiente

- Leer el aviso legal de navarra.es antes de difundir.
- Escribir al Servicio de Bibliotecas Públicas de Navarra: avisar de la herramienta y preguntar por API o export.
