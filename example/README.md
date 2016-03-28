# Map Experiment

An example experiment to run in coordination with the mapping application.

See documentation and resources at omf.mytestbed.net and oml.mytestbed.net.

## Building

    oml2-scaffold --make --main --force map_experiment.rb
    make

The development libraries don't seem to exist in Orbit Lab (at least not all
  resources), so build necessary oml2 libs and tools on a separate machine
and compile there.

## Running

Copy the executable and experiment definition to the Orbit Lab console, then
execute with OMF.

    omf exec map_experiment.rb --controller <ip of accessible interface>
