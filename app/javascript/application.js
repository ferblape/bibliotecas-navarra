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
