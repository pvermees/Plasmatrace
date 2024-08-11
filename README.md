# Plasmatrace

## Julia package for LA-ICP-MS data reduction

Plasmatrace is in early development and has not yet been added to the
[Julia](https://julialang.org/) package repository. However, if you
want to play around with the current functionality, then you can
install the package from GitHub. First, make sure that you have Julia
installed on your system by downloading it from
[here](https://julialang.org/downloads/#current_stable_release). Then,
at the Julia REPL:

```
import Pkg; Pkg.add(url="https://github.com/pvermees/Plasmatrace.git")
```

There are two ways to interact with Plasmatrace:

## 1. Interactive, text-based user interface.

Here is the shortest possible example of a menu-driven Plasmatrace session:

```
julia> using Plasmatrace
julia> PT!()
-------------------
 Plasmatrace 0.6.3 
-------------------

r: Read data files[*]
m: Specify the method[*]
t: Tabulate the samples
s: Mark mineral standards[*]
g: Mark reference glasses[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the results
l: Logs and templates
o: Options
u: Update
c: Clear
x: Exit
?: Help
x

julia>
```

## 2. Command-line API

Here is an example of a carbonate U-Pb data reduction using WC-1 for
time-dependent elemental fractionation correction between U and Pb and
NIST-612 for mass-dependent fractionation correction of the
Pb-isotopes. The script exports all the aliquots of the "Duff" sample
to a JSON file that can be opened in IsoplotR:

```
julia> method = "U-Pb"
julia> run = load("data/carbonate",instrument="Agilent")
julia> standards = Dict("WC1"=>"WC1")
julia> glass = Dict("NIST612"=>"NIST612")
julia> channels = Dict("d"=>"Pb207","D"=>"Pb206","P"=>"U238")
julia> blk, fit = process!(run,method,channels,standards,glass)
julia> export2IsoplotR(run,method,channels,fit,blk,prefix="Duff",fname="Duff.json")
```