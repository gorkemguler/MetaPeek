# Sample files

Synthetic images for checking that the forensics views actually work. Both were
generated from scratch, so they contain no real photographs or personal data.

| File | What is planted in it | Where it shows up |
| --- | --- | --- |
| `spliced-region.jpg` | A noisy gradient saved as JPEG once, then a freshly drawn rectangle reading "PASTED" composited on top and saved again. The pasted block has no compression history, so its error level differs from the rest of the frame. | Error Level Analysis |
| `lsb-hidden-text.png` | A gradient whose least significant bit, across all three colour channels, spells `CTF{h1dd3n}`. Invisible to the eye: the pixel values differ by at most 1. | Hidden Pixels (LSB) |

Open either one in MetaPeek and the corresponding card should reveal the planted
content. They are also useful for comparing MetaPeek against other tools such as
[FotoForensics](https://fotoforensics.com/).
