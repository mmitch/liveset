# LiveSet

MIDI performance via live edited Perl scripts.

This is essentially the same as live-patching a huge Eurorack system,
except that all the $$$ hardware is replaced by Perl scripts ;-)

Not much documentation here, everything is still being written.

## Minimal working example

1. Start the player using the provided examples:

```shell
cd examples
perl -I../ liveset-example.pl
```

2. While the demo is playing, edit `global.pl`, `bass.pl` or `drum.pl`
   with a text editor.  The files will reload after saving and you
   will hear the changes immediately.
