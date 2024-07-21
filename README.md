# Plasmatrace

## Julia package for LA-ICP-MS data reduction

Plasmatrace is in early development and has not yet been added to
the [Julia](https://julialang.org/) package repository. However, if
you want to play around with the current functionality, then you can
install the package from GitHub. At the Julia REPL:

```
import Pkg; Pkg.add(url="https://github.com/pvermees/Plasmatrace.git")
```

There are two ways to interact with Plasmatrace:

## 1. Interactive, text-based user interface.

Here is an example of a menu-driven Plasmatrace session:

```
julia> using Plasmatrace
julia> PT()
-------------------
 Plasmatrace 0.5.2
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
R: Refresh
x: Exit
?: Help
r

1: Agilent
2: ThermoFisher
x: Exit
?: Help
1

Enter the full path of the data directory (? for help, x to exit):
data/Lu-Hf

r: Read data files
m: Specify the method[*]
t: Tabulate the samples
s: Mark mineral standards[*]
g: Mark reference glasses[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the results
l: Logs and templates
o: Options
R: Refresh
x: Exit
?: Help
m

1: Lu-Hf
2: Rb-Sr
3: U-Pb
x: Exit
?: Help
1

Choose from the following list of channels:
1. Mg24 -> 24
2. Al27 -> 27
3. Ca43 -> 43
4. Ti47 -> 113
5. Fe57 -> 57
6. Sr88 -> 88
7. Y89 -> 172
8. Zr90 -> 173
9. La139 -> 154
10. Ce140 -> 155
11. Pr141 -> 141
12. Nd146 -> 146
13. Sm147 -> 147
14. Yb172 -> 172
15. Lu175 -> 175
16. Lu175 -> 257
17. Hf176 -> 258
18. Hf178 -> 260
and select the channels corresponding to the following isotopes or their proxies:
Lu176, Hf176, Hf177
Specify your selection as a comma-separated list of numbers:
15,17,18

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark mineral standards[*]
g: Mark reference glasses[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the results
l: Logs and templates
o: Options
R: Refresh
x: Exit
?: Help
s

a: Add a mineral standard
r: Remove mineral standards
l: List the available mineral standards
t: Tabulate all the samples
x: Exit
?: Help
a

Choose one of the following standards:
1: Hogsbo
2: BP
3: ME-1
x: Exit
?: Help
1

p: Select samples by prefix
n: Select samples by number
t: Tabulate all the samples
x: Exit
?: Help
p

Specify the prefix of the Hogsbo measurements (? for help, x to exit):
hogsbo

a: Add a mineral standard
r: Remove mineral standards
l: List the available mineral standards
t: Tabulate all the samples
x: Exit
?: Help
x

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark mineral standards
g: Mark reference glasses[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the results
l: Logs and templates
o: Options
R: Refresh
x: Exit
?: Help
g

a: Add a reference glass
r: Remove reference glasses
l: List the available reference glasses
t: Tabulate all the samples
x: Exit
?: Help
a

Choose one of the following reference glasses:
1: NIST610
2: NIST612
x: Exit
?: Help
2

p: Select analyses by prefix
n: Select analyses by number
t: Tabulate all the analyses
x: Exit
?: Help
p

Specify the prefix of the NIST612 measurements (? for help, x to exit):
NIST612

a: Add a reference glass
r: Remove reference glasses
l: List the available reference glasses
t: Tabulate all the samples
x: Exit
?: Help
x

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark mineral standards
g: Mark reference glasses
v: View and adjust each sample
p: Process the data[*]
e: Export the results
l: Logs and templates
o: Options
R: Refresh
x: Exit
?: Help
p
Fitting blanks...
Fractionation correction...
Done

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark mineral standards
g: Mark reference glasses
v: View and adjust each sample
p: Process the data
e: Export the results
l: Logs and templates
o: Options
R: Refresh
x: Exit
?: Help
e

a: All analyses
s: Samples only (no standards)
x: Exit
?: Help
or enter the prefix of the analyses that you want to select
s

c: Export to .csv
j: Export to .json
x: Exit
?: Help
j

Enter the path and name of the .json file (? for help, x to exit):
BP.json

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark mineral standards
g: Mark reference glasses
v: View and adjust each sample
p: Process the data
e: Export the results
l: Logs and templates
o: Options
R: Refresh
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