This is the FPL team blog.

Build this locally with: 
```
nix-build
```
where the output will be in `./release/blog`

Get to a local preview server with:
```
nix-shell
cabal configure
cabal build
./dist/build/site/site watch
```
where the content will be served from http://localhost:8000/

There is a post in there describing how to contribute, which you can reach [here](https://github.com/qfpl/blog/blob/master/posts/writing-for-the-fp-blog.md).
