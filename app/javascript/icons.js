import { createIcons, icons } from "lucide";

// Caution, this will import all the icons and bundle them.
document.addEventListener("turbo:load", () => {
  createIcons({ icons });
});
