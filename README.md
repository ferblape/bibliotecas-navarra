# Bibliotecas de Navarra

Una web sencilla para buscar en el catálogo de las Bibliotecas Públicas de Navarra, filtrar por biblioteca y ver si hay ejemplares disponibles, sin pelearse con el OPAC oficial.

No es un servicio oficial del Gobierno de Navarra ni de sus bibliotecas. Cada búsqueda consulta el [OPAC](https://www.navarra.es/opac/abnetcl.exe?ACC=101) en vivo; no copiamos el catálogo.

## Qué hace

- Busca en todo el catálogo o en una biblioteca, por cualquier campo, título, autor o materia. La biblioteca elegida se recuerda en una cookie.
- Muestra cada ficha con sus ejemplares por biblioteca y su disponibilidad, la biblioteca elegida primero, y enlaza a la ficha oficial.
- Guarda favoritos en una lista anónima: no hay cuentas, la dirección secreta `/listas/<token>` es la llave. Quien la conoce puede verla y cambiarla.
- Enseña en la portada los últimos libros visitados en este navegador.
- Lista las bibliotecas con su dirección, un enlace a Google Maps, teléfono, correo y su ficha oficial (`/bibliotecas`).
- Si una búsqueda da 3 resultados o menos, propone una corrección ("¿Quisiste decir *anna kadabra*?"). Para eso envía la búsqueda a Google Books, que tolera errores, y cambia cada palabra por la más parecida de los títulos y autores que encuentra (`app/models/suggestion.rb`). Necesita la clave `google_books.api_key` en las credenciales; sin ella, no hay sugerencias.
- Ofrece el catálogo a agentes de IA por MCP (ver más abajo).

En producción: https://bibliotecas-navarra.fly.dev

## Cómo funciona

El OPAC es un AbsysNet sin API: la app abre una sesión, envía los formularios en ISO-8859-1 y lee el HTML con Nokogiri.

- `app/models/opac/`: `Opac::Session` abre y cierra sesiones del OPAC; `ResultsPage`, `RecordPage` y `LibrariesPage` leen sus páginas.
- `app/models/catalog.rb`: la fachada que usa la app. Cachea búsquedas y fichas 10 minutos y la lista de bibliotecas un día. Si el OPAC falla, la app muestra "catálogo no disponible".
- `List` y `Bookmark`: las listas de favoritos, en SQLite. Los libros visitados van en una cookie firmada (`RecentRecords`).
- `LibraryDirectory`: dónde está cada biblioteca, leído de `config/libraries.yml` (ver abajo).

### Direcciones de las bibliotecas

Vienen del [directorio de bibliotecas de navarra.es](https://www.navarra.es/es/bibliotecas/directorio) y se guardan en `config/libraries.yml`, versionado en el repo. `bin/rails libraries:import` lo regenera: lee el directorio, empareja cada centro con su biblioteca del OPAC por el nombre y baja la dirección, los teléfonos y los correos de su ficha. Las bibliotecas cuyos nombres no coinciden se emparejan a mano en `config/library_overrides.yml`. No se copian los horarios, porque cambian según la época: la página enlaza a la ficha oficial.

La importación no se ejecuta al desplegar. La GitHub Action `Refresh libraries` la lanza el día 1 de cada mes y abre una PR si algo ha cambiado; también se puede lanzar a mano desde la pestaña Actions.

Para cargar poco el OPAC: caché, cada sesión se cierra en cuanto se lee la respuesta, límite de 30 peticiones por minuto por visitante y respuesta 403 a buscadores y crawlers (`lib/middleware/block_crawlers.rb`). El OPAC rechaza sesiones nuevas ("Error 205") si hay demasiadas abiertas.

Las decisiones y lo que se sabe del OPAC están en [`docs/plans/2026-11-15-catalogo-wrapper.md`](docs/plans/2026-11-15-catalogo-wrapper.md).

## MCP para agentes de IA

La app es también un servidor [MCP](https://modelcontextprotocol.io) en **https://bibliotecas-navarra.fly.dev/mcp** (Streamable HTTP, sin autenticación, solo lectura). Herramientas:

- `list_libraries`: las bibliotecas con el código que sirve para filtrar por una de ellas.
- `search_catalog`: busca por `query`, opcionalmente en un `field` (`any`, `title`, `author`, `subject`), en una `library` y en una `page`. Devuelve 10 fichas por página y el total.
- `get_record`: una ficha con sus ejemplares, la biblioteca de cada uno, su signatura y si está disponible. Con `library`, solo los ejemplares de esa biblioteca.

Para instalarlo:

- Claude Code: `claude mcp add --transport http bibliotecas-navarra https://bibliotecas-navarra.fly.dev/mcp`
- claude.ai o Claude Desktop: Ajustes → Conectores → Añadir conector personalizado, con la URL de arriba.
- Otros clientes: cualquier cliente MCP con transporte HTTP, apuntando a la misma URL.

Hay una página para personas que explica todo esto en https://bibliotecas-navarra.fly.dev/agentes.

### Sin MCP

Los agentes que solo leen páginas web tienen las instrucciones en [`/llms.txt`](https://bibliotecas-navarra.fly.dev/llms.txt), y la búsqueda y las fichas en Markdown:

- `/?q=TÉRMINOS&format=md`, con `field`, `library` y `page` como en la web. Sin `q`, la lista de bibliotecas y sus códigos.
- `/records/ID.md`: una ficha con sus ejemplares por biblioteca.

`robots.txt` deja fuera a los buscadores, pero permite estas rutas a los agentes que leen por encargo de una persona.

Cada petición se responde por separado (sin sesión MCP). Para no saturar el OPAC hay un límite de 10 peticiones por minuto por agente y de 60 por minuto entre todos; al pasarlo, el servidor responde con un error que pide esperar un minuto. El código está en `app/controllers/mcp_controller.rb` y `app/tools/`.

## Desarrollo

Ruby 4.0 y Rails 8.1, con SQLite.

```sh
bin/setup --skip-server   # gemas y base de datos
bin/dev                   # servidor en http://localhost:3000 (otro puerto: bin/dev -p 3001)
```

## Tests

```sh
bin/rails test            # sin red; los tests contra el OPAC real se saltan
OPAC_LIVE=1 bin/rails test   # también contra el OPAC real
GOOGLE_BOOKS_LIVE=1 bin/rails test   # también contra Google Books (necesita RAILS_MASTER_KEY)
bin/ci                    # rubocop, auditorías de seguridad y tests, como en GitHub
```

Los tests contra el OPAC real no usan mocks y corren en un solo proceso. Lánzalos de uno en uno: varias pasadas seguidas pueden saturar las sesiones del OPAC.

## Producción

Una máquina de Fly.io en París (`cdg`) con un volumen para las bases SQLite (Solid Cache y listas), copiadas de forma continua a un bucket de Tigris con Litestream. La máquina se para cuando no hay tráfico y arranca con la siguiente petición, que tarda unos segundos más.

Se despliega con `fly deploy`. La puesta en marcha, los despliegues y cómo restaurar copias están en [`docs/deploy.md`](docs/deploy.md).
