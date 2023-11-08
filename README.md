# Plasmatrace.jl

## Julia package for LA-ICP-MS data reduction

Plasmatrace.jl is in early development and has not yet been added to
the [Julia](https://julialang.org/) package repository. However, if
you want to play around with the current functionality, then you can
install the package from GitHub. At the Julia REPL:

```
import Pkg; Pkg.add(url="https://github.com/pvermees/Plasmatrace.jl.git")
```

There are two ways to interact with Plasmatrace:

## 1. Interactive, text-based user interface.

Here is an example of a menu-driven Plasmatrace session:

```
julia> using Plasmatrace
julia> PT()
-------------------
 Plasmatrace 0.2.1
-------------------

f: Load the data files[*]
m: Specify a method[*]
b: Bulk settings[*]
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
f
i. Specify your instrument[*]
r. Open and read the data files[*]
l. List all the samples in the session
x. Exit
i
Choose a file format:
1. Agilent
1
i. Specify your instrument
r. Open and read the data files[*]
l. List all the samples in the session
x. Exit
r
Enter the full path of the data directory:
/home/pvermees/Documents/Plasmatrace/Garnet/
i. Specify your instrument
r. Open and read the data files
l. List all the samples in the session
x. Exit
x
f: Load the data files
m: Specify a method[*]
b: Bulk settings[*]
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
m
Choose an application:
1. Lu-Hf
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
Lu176,Hf177,Hf176
Specify your selection as a comma-separated list of numbers:
15,17,18
f: Load the data files
m: Specify a method
b: Bulk settings[*]
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
b
b. Set default blank windows[*]
w. Set default signal windows[*]
p. Add a standard by prefix[*]
n. Adjust the order of the polynomial fits
l. List all the standards
r. Remove a standard
x. Exit
b
a: automatic
s: set a one-part window
m: set a multi-part window
a
b. Set default blank windows
w. Set default signal windows[*]
p. Add a standard by prefix[*]
n. Adjust the order of the polynomial fits
l. List all the standards
r. Remove a standard
x. Exit
w
a: automatic
s: set a one-part window
m: set a multi-part window
a
b. Set default blank windows
w. Set default signal windows
p. Add a standard by prefix[*]
n. Adjust the order of the polynomial fits
l. List all the standards
r. Remove a standard
x. Exit
x
f: Load the data files
m: Specify a method
b: Bulk settings[*]
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
b
b. Set default blank windows
w. Set default signal windows
p. Add a standard by prefix[*]
n. Adjust the order of the polynomial fits
l. List all the standards
r. Remove a standard
x. Exit
p
s: Use a single primary reference material
m: Use multiple primary reference materials
s
Enter the prefix of the reference material:
BP
Now match this prefix with one of the following reference materials:
1. Hogsbo
2. BP
2
b. Set default blank windows
w. Set default signal windows
p. Add a standard by prefix
n. Adjust the order of the polynomial fits
l. List all the standards
r. Remove a standard
x. Exit
x
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
p
Fitting blanks...
Fitting standards...
f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
e
s. Export one sample
m. Export multiple samples
a. Export all samples
s
Enter the prefix of the sample to export:
hogsbo
j: export to .json
c: export to .csv
x. Exit
c
Enter the path and name of the .csv file:
/home/pvermees/Desktop/hogsbo.csv

f: Load the data files
m: Specify a method
b: Bulk settings
v: View and adjust each sample
p: Process the data
e: Export the results
l: Import/export a session log
x: Exit
x

julia>
```

## 2. Command-line API

Here is an example of a Lu-Hf calibration using two mineral standards.
The blanks are fitted using a second order polynomial, whereas the
signal drift is modelled using a linear function:

```
julia> dname = "/home/pvermees/Documents/Plasmatrace/Garnet/";
julia> session = load(dname,instrument="Agilent");
julia> setMethod!(session,method="LuHf",
       channels=["Lu175 -> 175","Hf178 -> 260","Hf176 -> 258"])
julia> setBlanks!(session);
julia> setSignals!(session);
julia> fitBlanks!(session,n=2);
julia> markStandards!(session,prefix="hogsbo_",standard=1);
julia> markStandards!(session,prefix="BP -",standard=2);
julia> fitStandards!(session,refmat=["Hogsbo","BP"],n=1,m=0);
julia> p = plot(session,i=15)
julia> display(p)
```