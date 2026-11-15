# Bibliotecas de Navarra

Una web sencilla para buscar en el catálogo de las Bibliotecas Públicas de Navarra, filtrar por biblioteca y ver si hay ejemplares disponibles, sin pelearse con el OPAC oficial.

No es un servicio oficial del Gobierno de Navarra ni de sus bibliotecas. Cada búsqueda consulta el [OPAC](https://www.navarra.es/opac/abnetcl.exe?ACC=101) en vivo; no copiamos el catálogo.

## Qué hace

- Busca en todo el catálogo o en una biblioteca, por cualquier campo, título, autor o materia. La biblioteca elegida se recuerda en una cookie.
- Muestra cada ficha con sus ejemplares por biblioteca y su disponibilidad, la biblioteca elegida primero, y enlaza a la ficha oficial.
- Guarda favoritos en una lista anónima: no hay cuentas, la dirección secreta `/listas/<token>` es la llave. Quien la conoce puede verla y cambiarla.
- Enseña en la portada los últimos libros visitados en este navegador.

## Cómo funciona

El OPAC es un AbsysNet sin API: la app abre una sesión, envía los formularios en ISO-8859-1 y lee el HTML con Nokogiri.

- `app/models/opac/`: `Opac::Session` abre y cierra sesiones del OPAC; `ResultsPage`, `RecordPage` y `LibrariesPage` leen sus páginas.
- `app/models/catalog.rb`: la fachada que usa la app. Cachea búsquedas y fichas 10 minutos y la lista de bibliotecas un día. Si el OPAC falla, la app muestra "catálogo no disponible".
- `List` y `Bookmark`: las listas de favoritos, en SQLite. Los libros visitados van en una cookie firmada (`RecentRecords`).

Para cargar poco el OPAC: caché, cada sesión se cierra en cuanto se lee la respuesta, límite de 30 peticiones por minuto por visitante y un User-Agent propio. El OPAC rechaza sesiones nuevas ("Error 205") si hay demasiadas abiertas.

Las decisiones y lo que se sabe del OPAC están en [`docs/plans/2026-11-15-catalogo-wrapper.md`](docs/plans/2026-11-15-catalogo-wrapper.md).

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
bin/ci                    # rubocop, auditorías de seguridad y tests, como en GitHub
```

Los tests contra el OPAC real no usan mocks y corren en un solo proceso. Lánzalos de uno en uno: varias pasadas seguidas pueden saturar las sesiones del OPAC.

## Producción

La caché (Solid Cache) y las listas viven en SQLite en `storage/`, que tiene que estar en un disco persistente.
