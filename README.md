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
 Plasmatrace 0.3.0 
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
x: Exit
r

Choose a file format:
1. Agilent
x. Exit
1

Enter the full path of the data directory:
data

r: Read data files
m: Specify the method[*]
t: Tabulate the samples
s: Mark standards[*]
v: View and adjust each sample
p: Process the data[*]
e: Export the isotope ratios
l: Import/export a session log
o: Options
x: Exit
m

Choose a method:
1. Lu-Hf
x. Exit
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
176Lu, 176Hf, 177Hf
Specify your selection as a comma-separated list of numbers:

15,17,18

Which Hf-isotope is measured as Hf178 -> 260?
1. 174Hf
2. 177Hf
3. 178Hf
4. 179Hf
5. 180Hf

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
x: Exit
s

Choose an option:
t. Tabulate all the samples
p. Add a standard by prefix
n. Add a standard by number
N. Remove a standard by number
r. Remove all standards
x. Exit
p

Specify the prefix of the standard:
BP

Which of the following standards did you select?
1. Hogsbo
2. BP
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
x: Exit
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
x: Exit
e

Choose an option:
c. Export to .csv
j. Export to .json
x. Exit
c

Enter the path and name of the .csv file:
output/test.csv

r: Read data files
m: Specify the method
t: Tabulate the samples
s: Mark standards
v: View and adjust each sample
p: Process the data
e: Export the isotope ratios
l: Import/export a session log
o: Options
x: Exit
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