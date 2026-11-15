// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"

// Browsers do not let a page add itself to the bookmarks, so the list page offers the
// next best things: the share sheet, copying its address, and the keyboard shortcut.
document.addEventListener("turbo:load", () => {
  document.querySelectorAll("[data-share-url]").forEach(offerToKeepAddress)
})

function offerToKeepAddress(element) {
  const url = element.dataset.shareUrl
  const share = element.querySelector("[data-share]")
  const copy = element.querySelector("[data-copy]")
  const hint = element.querySelector("[data-bookmark-hint]")

  if (navigator.share) {
    share.hidden = false
    // Closing the share sheet rejects the promise; there is nothing to do then.
    share.addEventListener("click", () => navigator.share({ title: element.dataset.shareTitle, url }).catch(() => {}))
  }

  if (navigator.clipboard) {
    const label = copy.textContent
    copy.hidden = false
    copy.addEventListener("click", async () => {
      await navigator.clipboard.writeText(url)
      copy.textContent = "Copiada ✓"
      setTimeout(() => { copy.textContent = label }, 2000)
    })
  }

  // Keyboards come with a mouse or a trackpad; phones and tablets have neither.
  if (matchMedia("(pointer: fine)").matches) {
    const shortcut = /Mac|iPhone|iPad/.test(navigator.platform) ? "⌘D" : "Ctrl+D"
    hint.textContent = `o pulsa ${shortcut} para guardarla en tus marcadores.`
    hint.hidden = false
  }
}

// The copies of a record, sorted by how far their library is from the visitor. The
// position stays in the browser: the distances are worked out here, never on the server.
document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".copies").forEach(offerToSortByDistance)
})

function offerToSortByDistance(copies) {
  const button = copies.querySelector("[data-sort-by-distance]")
  if (!button || !navigator.geolocation) return

  const sort = () => {
    button.disabled = true
    navigator.geolocation.getCurrentPosition(
      ({ coords }) => sortByDistance(copies, coords),
      () => { button.hidden = true },
      { maximumAge: 10 * 60 * 1000, timeout: 15 * 1000 }
    )
  }

  button.hidden = false
  button.addEventListener("click", sort)

  // Visitors who already shared their position get the copies sorted without asking again.
  navigator.permissions?.query({ name: "geolocation" }).then((permission) => {
    if (permission.state === "granted") sort()
    if (permission.state === "denied") button.hidden = true
  }).catch(() => {})
}

function sortByDistance(copies, position) {
  const libraries = [ ...copies.querySelectorAll("details[data-coordinates]") ].map((library) => {
    const distances = JSON.parse(library.dataset.coordinates).map(([ latitude, longitude ]) => kilometres(position, { latitude, longitude }))
    const distance = Math.min(...distances)
    library.querySelector("[data-distance]").textContent = Number.isFinite(distance) ? formatKilometres(distance) : ""
    return { library, distance }
  })

  libraries.sort((a, b) => a.distance - b.distance).forEach(({ library }) => copies.append(library))
  copies.querySelector("[data-sort-by-distance]").hidden = true
  copies.querySelector("[data-distance-note]").hidden = false
}

// Haversine distance between two points on the Earth.
function kilometres(from, to) {
  const radians = (degrees) => degrees * Math.PI / 180
  const a = Math.sin(radians(to.latitude - from.latitude) / 2) ** 2 +
    Math.cos(radians(from.latitude)) * Math.cos(radians(to.latitude)) * Math.sin(radians(to.longitude - from.longitude) / 2) ** 2
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

function formatKilometres(distance) {
  return `${distance.toLocaleString("es", { maximumFractionDigits: distance < 10 ? 1 : 0 })} km`
}
