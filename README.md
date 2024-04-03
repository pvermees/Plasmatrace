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
 Plasmatrace 0.4.0 
-------------------

r: Read data files[*]
m: Specify the method[*]
t: Tabulate the samples
s: Mark standards[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the isotope ratios
l: Import/export a session log
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
s: Mark standards[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the isotope ratios
l: Import/export a session log
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

Which isotope is measured as "Hf178 -> 260"?
1: Hf174
2: Hf177
3: Hf178
4: Hf179
5: Hf180
x: Exit
?: Help
3

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark standards[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the isotope ratios
l: Import/export a session log
o: Options
R: Refresh
x: Exit
?: Help
s

t: Tabulate all the samples
p: Add a standard by prefix
n: Add a standard by number
N: Remove a standard by number
r: Remove all standards
x: Exit
?: Help
p

Specify the prefix of the standard (? for help, x to exit):
BP

Which of the following standards did you select?
1: Hogsbo
2: BP
x: Exit
?: Help
2

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark standards
v: View and adjust each sample
p: Process the data[*]
e: Export the isotope ratios
l: Import/export a session log
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
s: Mark standards
v: View and adjust each sample
p: Process the data
e: Export the isotope ratios
l: Import/export a session log
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
output/test.json

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark standards
v: View and adjust each sample
p: Process the data
e: Export the isotope ratios
l: Import/export a session log
o: Options
R: Refresh
x: Exit
?: Help
x

julia> 
```

## 2. Command-line API

Here is an example of a Lu-Hf calibration using two mineral standards.
The blanks are fitted using a second order polynomial, whereas the
signal drift is modelled using a linear function:

```
julia> run = load("/home/mydata",instrument="Agilent")
julia> blk = fitBlanks(run,n=2)
julia> standards = Dict("BP" => "BP", "Hogsbo" => "hogsbo_ana")
julia> setStandards!(run,standards)
julia> anchors = getAnchor("Lu-Hf",standards)
julia> channels = Dict("d"=>"Hf178 -> 260","D"=>"Hf176 -> 258","P"=>"Lu175 -> 175")
julia> fit = fractionation(run,blank=blk,channels=channels,anchors=anchors,mf=1.4671)
julia> ratios = averat(run,channels=channels,pars=fit,blank=blk)
julia> CSV.write("out.csv", ratios)
```