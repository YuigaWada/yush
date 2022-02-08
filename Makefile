dune: 
	dune build && mv -f _build/default/yush.exe ./yush && ./yush

format: 
	ocamlformat yush.ml --inplace --enable-outside-detected-project

clean:
	rm  -rf ./_build
