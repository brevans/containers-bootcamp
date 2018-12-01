pandoc --to=revealjs --standalone \
   --output=index.html containers-presentation.md \
   --variable=revealjs-url:https://revealjs.com \
   --variable=theme:white \
   --variable=center:false \
   --variable=transition:none