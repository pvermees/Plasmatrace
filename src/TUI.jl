function PT(logbook="")
    welcome()
    ctrl = Dict(
        "priority" => Dict("load" => true, "method" => true,
                           "standards" => true, "process" => true),
        "history" => DataFrame(task=String[],action=String[]),
        "chain" => ["top"],
        "i" => 1,
        "den" => nothing,
        "options" => Dict("blank" => 2, "drift" => 1, "down" => 1),
        "mf" => 1.0,
        "head2name" => true,
        "PAcutoff" => nothing,
        "par" => Pars[],
        "anchors" => nothing,
        "blank" => nothing,
        "instrument" => "",
        "method" => "",
        "channels" => Dict(),
        "selection" => Int[],
        "transformation" => "sqrt",
        "refresher" => Dict(
            "dname" => "",
            "prefixes" => AbstractString[],
            "refmats" => AbstractString[]
        )
    )
    if logbook != ""
        TUIimportLog!(ctrl,logbook)
    end
    while true
        if length(ctrl["chain"])<1 return end
        try
            dispatch!(ctrl,verbose=false)
        catch e
            println(e)
        end
    end
end
export PT

function dispatch!(ctrl::AbstractDict;
                   key=nothing,response=nothing,verbose=false)
    if (verbose)
        println(ctrl["chain"])
    end
    if isnothing(key) key = ctrl["chain"][end] end
    (message,help,action) = tree(ctrl)[key]
    if isa(message,Function)
        println("\n"*message(ctrl))
    else
        println("\n"*message)
    end
    if isnothing(response) response = readline() end
    if response == "?"
        println(help)
        next = nothing
    elseif response in ["x","xx","xxx"]
        next = response
    elseif isa(action,Function)
        next = action(ctrl,response)
    else
        next = action[response]
    end
    if isa(next,Function)
        next(ctrl)
    elseif next == "x"
        if length(ctrl["chain"])<1 return end
        pop!(ctrl["chain"])
    elseif next == "xx"
        if length(ctrl["chain"])<2 return end
        pop!(ctrl["chain"])
        pop!(ctrl["chain"])
    elseif next == "xxx"
        if length(ctrl["chain"])<3 return end
        pop!(ctrl["chain"])
        pop!(ctrl["chain"])
        pop!(ctrl["chain"])
    elseif isnothing(next)
        if length(ctrl["chain"])<1 return end
    else
        push!(ctrl["chain"],next)
    end
    if key != "import"
        push!(ctrl["history"],[key,response])
    end
end

function tree(ctrl::AbstractDict)
    Dict(
        "top" => (
            message =
            "r: Read data files"*check(ctrl,"load")*"\n"*
            "m: Specify the method"*check(ctrl,"method")*"\n"*
            "t: Tabulate the samples\n"*
            "s: Mark standards"*check(ctrl,"standards")*"\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data"*check(ctrl,"process")*"\n"*
            "e: Export the isotope ratios\n"*
            "l: Import/export a session log\n"*
            "o: Options\n"*
            "R: Refresh\n"*
            "x: Exit\n"*
            "?: Help",
            help = "This is the top-level menu. Asterisks (*) "*
            "mark compulsory steps. Refresh reloads the data directory "*
            "and only works if the asterisks are gone.",
            action = Dict(
                "r" => "instrument",
                "m" => "method",
                "t" => TUItabulate,
                "s" => "standards",
                "v" => TUIviewer!,
                "p" => TUIprocess!,
                "e" => "export",
                "l" => "log",
                "o" => "options",
                "R" => TUIrefresh!
            )
        ),
        "instrument" => (
            message =
            "1: Agilent\n"*
            "2: ThermoFisher\n"*
            "x: Exit\n"*
            "?: Help",
            help = "Choose a file format. Email us if you don't "*
            "find your instrument in this list.",
            action = TUIinstrument!
        ),
        "load" => (
            message = "Enter the full path of the data directory "*
            "(? for help, x to exit):",
            help = "Plasmatrace will read all the files in this folder. "*
            "You don't need to select the files, just the folder.",
            action = TUIload!,
        ),
        "method" => (
            message = TUIshowMethods,
            help = "Choose a geochronometer. Email us if you can't "*
            "find your chosen method.",
            action = TUImethod!
        ),
        "columns" => (
            message = TUIcolumnMessage,
            help = nothing,
            action = TUIcolumns!
        ),
        "iratio" => (
            message = TUIiratioMessage,
            help =
            "Plasmatrace does not know which data label corresponds to "*
            "which isotope. Sometimes one non-radiogenic isotope is used "*
            "as a proxy for another. This must be specified for the "*
            "proxy conversion to work.",
            action = TUIiratio!
        ),
        "standards" => (
            message =
            "t: Tabulate all the samples\n"*
            "p: Add a standard by prefix\n"*
            "n: Add a standard by number\n"*
            "N: Remove a standard by number\n"*
            "r: Remove all standards\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Choose one or more primary reference materials. "*
            "Note that secondary reference materials should be "*
            "treated as regular samples.",
            action = Dict(
                "t" => TUItabulate,
                "p" => "addStandardsByPrefix",
                "n" => "addStandardsByNumber",
                "N" => "removeStandardsByNumber",
                "r" => TUIresetStandards!
            )
        ),
        "addStandardsByPrefix" => (
            message = "Specify the prefix of the standard "*
            "(? for help, x to exit):",
            help =
            "For example, suppose that Plesovice zircon reference "*
            "materials are named STDCZ01, STDCZ02, ..., then you can "*
            "select all the standards by entering STDCZ here. "*
            "Enter 'x' to go up one level and tabulate the "*
            "sample if you forgot the exact prefix of your standards.",
            action = TUIaddStandardsByPrefix!
        ),
        "addStandardsByNumber" => (
            message =
            "Select the standards as a comma-separated list of numbers "*
            "(? for help, x to exit):",
            help =
            "For example, suppose that the analyses are labelled as "*
            "G001, G002, ..., then it is not possible to identify "*
            "the standards by prefix, but you can still select them "*
            "by sequence number (e.g., 1,2,8,9,15,16,...).",
            action = TUIaddStandardsByNumber!
        ),
        "removeStandardsByNumber" => (
            message =
            "Select the standards as a comma-separated list of numbers "*
            "(? for help, x to exit):",
            help =
            "'bad' standards can be removed one-by-one, by specifying "*
            "their number. Enter 'x' to go up one level and tabulate "*
            "the sample if you forgot the exact prefix of your standards.",
            action = TUIremoveStandardsByNumber!
        ),
        "refmat" => (
            message = TUIshowRefmats,
            help =
            "Even though you may have specified the prefix of your "*
            "reference materials, Plasmatrace still does not know "*
            "which standard this refers to. That information can be "*
            "specified here. If you do not find your reference material "*
            "in this list, then you can either specify your own 
            reference material under 'options' in the top menu, or "*
            "you can email us to add the material to the software.",
            action = TUIsetStandards!
        ),
        "view" => (
            message = 
            "n: Next\n"*
            "p: Previous\n"*
            "g: Go to\n"*
            "t: Tabulate all the samples in the session\n"*
            "r: Plot signals or ratios?\n"*
            "b: Select blank window(s)\n"*
            "s: Select signal window(s)\n"*
            "T: Choose a data transformation\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "It is useful to view all the samples in your analytical "*
            "sequence at least once, to modify blank and signal "*
            "windows or checking the fit to the standards.",
            action = Dict(
                "n" => TUInext!,
                "p" => TUIprevious!,
                "g" => "goto",
                "t" => TUItabulate,
                "r" => "setDen",
                "b" => "Bwin",
                "s" => "Swin",
                "T" => "transformation"
            )
        ),
        "goto" => (
            message = "Enter the number of the sample to plot "*
            "(? for help, x to exit):",
            help = "Jump to a specific analysis.",
            action = TUIgoto!
        ),
        "setDen" => (
            message = TUIratioMessage,
            help =
            "Plot the ratios of the channels relative to a common "*
            "denominator. Zero values for the denominator are omitted.",
            action = TUIratios!
        ),
        "Bwin" => (
            message =
            "Choose an option to set the blank window(s):\n"*
            "a: Automatic (current sample)\n"*
            "s: Manually set a one-part window (current sample)\n"*
            "m: Manually set a multi-part window (current sample)\n"*
            "A: Automatic (all samples)\n"*
            "S: Manually set a one-part window (all samples)\n"*
            "M: Manually set a multi-part window (all samples)\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Specify the blank (background signal) as pairs of time "*
            "stamps (in seconds) or trust Plasmatrace to choose the "*
            "blank windows automatically. The blanks of all the "*
            "analyses (samples + blanks) will be combined and "*
            "interpolated under the signal.",
            action = Dict(
                "a" => TUIoneAutoBlankWindow!,
                "s" => "oneSingleBlankWindow",
                "m" => "oneMultiBlankWindow",
                "A" => TUIallAutoBlankWindow!,
                "S" => "allSingleBlankWindow",
                "M" => "allMultiBlankWindow"
            )
        ),
        "Swin" => (
            message =
            "Choose an option to set the signal window(s):\n"*
            "a: Automatic (current sample)\n"*
            "s: Manually set a one-part window (current sample)\n"*
            "m: Manually set a multi-part window (current sample)\n"*
            "A: Automatic (all samples)\n"*
            "S: Manually set a one-part window (all samples)\n"*
            "M: Manually set a multi-part window (all samples)\n"*
            "x: Exit\n"*
            "?: Help",
            help = 
            "Specify the signal as pairs of time stamps (in seconds) "*
            "or trust Plasmatrace to choose the signal windows "*
            "automatically. The signals of the reference materials "*
            "are used to define the drift and fractionation "*
            "corrections, which are then applied to the samples.",
            action = Dict(
                "a" => TUIoneAutoSignalWindow!,
                "s" => "oneSingleSignalWindow",
                "m" => "oneMultiSignalWindow",
                "A" => TUIallAutoSignalWindow!,
                "S" => "allSingleSignalWindow",
                "M" => "allMultiSignalWindow"
            )
        ),
        "transformation" => (
            message =
            "Choose a data transformation for the y-axis:\n"*
            "l: Linear\n"*
            "L: Logarithmic\n"*
            "s: Square root\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Using a square root or log-transform makes it easier to compare "*
            "signal strengths or signal ratios that vary over several "*
            "orders of magnitude.",
            action = TUItransformation!
        ),
        "oneSingleBlankWindow" => (
            message =
            "Enter the start and end point of the selection window "*
            "(in seconds). Type '?' for help and 'x' to exit.",
            help =
            "Specify the start and end point of the blank window "*
            "as a comma-separated pair of numbers. For example: "*
            "0,20 marks a blank window from 0 to 20 seconds.",
            action = TUIoneSingleBlankWindow!
        ),
        "oneMultiBlankWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds)\n"*
            "Type '?' for help and 'x' to exit.",
            help =
            "Specify the start and end points of the blank window "*
            "as a comma-separated list of bracketed pairs "*
            " of numbers. For example: (0,20),(25,30) marks a two-part "*
            "selection window from 0 to 20s, and from 25 to 30s.",
            action = TUIoneMultiBlankWindow!
        ),
        "allSingleBlankWindow" => (
            message =
            "Enter the start and end point of the selection window "*
            "(in seconds). Type '?' for help and 'x' to exit.",
            help =
            "Specify the start and end point of the blank windows "*
            "as a comma-separated pair of numbers. For example: "*
            "0,20 marks a blank window from 0 to 20 seconds.",
            action = TUIallSingleBlankWindow!
        ),
        "allMultiBlankWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds). "*
            "Type '?' for help and 'x' to exit.",
            help =
            "Specify the start and end points of the blank windows "*
            "as a comma-separated list of bracketed pairs "*
            " of numbers. For example: (0,20),(25,30) marks a two-part "*
            "selection window from 0 to 20s, and from 25 to 30s.",
            action = TUIallMultiBlankWindow!
        ),
        "oneSingleSignalWindow" => (
            message =
            "Enter the start and end point of the selection window "*
            "(in seconds). Type '?' for help and 'x' to exit.",
            help =
            "Specify the start and end points of the signal window "*
            "as a comma-separated pair of numbers. For example: "*
            "30,60 marks a signal window from 30 to 60 seconds.",
            action = TUIoneSingleSignalWindow!
        ),
        "oneMultiSignalWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds). "*
            "Type '?' for help and 'x' to exit.",
            help =
            "Specify the start and end points of the signal window "*
            "as a comma-separated list of bracketed pairs "*
            "of numbers. For example: (40,45),(50,60) marks a two-part "*
            "signal window from 40 to 45s, and from 50 to 60s.",
            action = TUIoneMultiSignalWindow!
        ),
        "allSingleSignalWindow" => (
            message =
            "Enter the start and end point of the selection windows "*
            "(in seconds). Type '?' for help and 'x' to exit.",
            help =
            "Specify the start and end points of the signal windows "*
            "as a comma-separated pair of numbers. For example: "*
            "30,60 marks a signal window from 30 to 60 seconds.",
            action = TUIallSingleSignalWindow!
        ),
        "allMultiSignalWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection windows (in seconds)\n"*
            "Type 'h' for help.",
            help =
            "Specify the start and end points of the signal windows "*
            "as a comma-separated list of bracketed pairs "*
            "of numbers. For example: (40,45),(50,60) marks a two-part "*
            "signal window from 40 to 45s, and from 50 to 60s.",
            action = TUIallMultiSignalWindow!
        ),
        "options" => (
            message =
            "b: Set the polynomial order of the blank correction\n"*
            "d: Set the polynomial order of the drift correction\n"*
            "h: Set the polynomial order of the down hole "*
            "fractionation correction\n"*
            "f: Fix or fit the fractionation factor\n"*
            "p: Subset the data by P/A cutoff\n"*
            "l: List the available reference materials\n"*
            "r: Define new reference materials\n"*
            "n: Configure the file name reader\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Advanced settings to override the default behaviour "*
            "of Plasmatrace. See the individual options for "*
            "further information.",
            action = Dict(
                "b" => "setNblank",
                "d" => "setNdrift",
                "h" => "setNdown",
                "f" => "setmf",
                "p" => "PA",
                "l" => TUIRefMatTab,
                "r" => "addRefMat",
                "n" => "head2name"
            )
        ),
        "setNblank" => (
            message =
            "Enter a non-negative integer (current value = "*
            string(ctrl["options"]["blank"])*", ? for help, x to exit):",
            help =
            "The blank is fitted by the following equation: "*
            "b = exp(a[1]) + exp(a[2])*t[1] + ... + exp(a[n])*t^(n-1). "*
            "Here you can specify the value of n.",
            action = TUIsetNblank!
        ),
        "setNdrift" => (
            message =
            "Enter a non-negative integer (current value = "*
            string(ctrl["options"]["drift"])*", ? for help, x to exit)",
            help =
            "The session drift is fitted by the following equation: "*
            "d = exp( a[1] + a[2]*t + ... + a[n]*t^(n-1) ). "*
            "Here you can specify the value of n.",
            action = TUIsetNdrift!
        ),
        "setNdown" => (
            message =
            "Enter a non-negative integer (current value = "*
            string(ctrl["options"]["down"])*", ? for help, x to exit)",
            help =
            "The down-hole drift is fitted by the following equation: "*
            "d = exp( a[1]*t + a[2]*t^2 + ... + a[n]*t^n ). "*
            "Here you can specify the value of n.",
            action = TUIsetNdown!
        ),
        "setmf" => (
            message =
            "Click [Enter] to treat the mass fractionation as a free "*
            "parameter, or enter a decimal number (currently "*
            (isnothing(ctrl["mf"]) ?
             "fitted" : ("fixed at "*string(ctrl["mf"])))*
            ", ? for help, x to exit)",
            help =
            "Clicking [Enter] tells Plasmatrace to estimate the mass "*
            "fractionation factor by forcing the y-intercept of an "*
            "inverse isochron to coincide with a prescribed value. "*
            "This works well for reference materials that form a "*
            "well defined isochron. For reference materials that are "*
            "very radiogenic, it is often better to stick with the "*
            "default value, which is 1 if the non-radiogenic isochron "*
            "isotope is measured directly, or the IUPAC recommended "*
            "ratio if the non-radiogenic isotope is measured by proxy",
            action = TUIsetmf!
        ),
        "PA" => (
            message =
            "l: List the maximum signal strength for each file\n"*
            "a: Add a pulse/analog cutoff\n"*
            "r: Remove the pulse/analog cutoff\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "On single collector ICP-MS instruments, low intensity "*
            "ion beams are measured in 'pulse' (P) mode and high "*
            "intensity ion beams are measured in 'analog' (A) mode. "*
            "The intercalibration of these two modes is not always "*
            "perfect. Here you can set or remove the cutoff value "*
            "between P and A mode, so that you can group samples "*
            "and standards according to them.",
            action = Dict(
                "l" => TUIPAlist,
                "a" => "setPAcutoff",
                "r" => TUIclearPAcutoff!
            )
        ),
        "setPAcutoff" => (
            message =
            "Enter the cutoff between pulse and analog mode in cps "*
            "(? for help, x to exit):",
            help =
            "After entering this value, samples and standards will be "*
            "split into two groups, corresponding to pulse mode (maximum "*
            "signal below the cutoff) and analog mode (maximum signal "*
            "above the cutoff).",
            action = TUIsetPAcutoff!
        ),
        "addRefMat" => (
            message =
            "Enter the path to the standards file (? for help, x to exit)",
            help =
            "Add new isotopic reference materials to Plasmatrace "*
            "by specifying the path to a .csv file that is "*
            "formatted as follows:\n\n"*
            "method,name,t,st,y0,sy0\n"*
            "Lu-Hf,Hogsbo,1029,1.7,3.55,0.05\n"*
            "Lu-Hf,BP,1745,5.0,3.55,0.05\n\n"*
            "where 't' is the age of the sample, 'y0' is the "*
            "y-intercept of the inverse isochron, and 'st' and 'sy0' "*
            "are their standard errors, which are not used for the "*
            "calculations in this version of the sofware.",
            action = TUIaddRefMat!
        ),
        "head2name" => (
            message =
            "h: Extract the sample names from the file headers\n"*
            "f: Extract the sample names from the file names\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "In most cases, the name of each ablation spot is "*
            "registered in the headers of the input files. However, "*
            "occasionally, the headers contain generic names (e.g., "*
            "spot01, spot02, ...) and the spot name must be inferred "*
            "from the file name (e.g. /path/to/data/Plesovice-01.csv)",
            action = TUIhead2name!
        ),
        "export" => (
            message =
            "a: All analyses\n"*
            "s: Samples only (no standards)\n"*
            "x: Exit\n"*
            "?: Help\n"*
            "or enter the prefix of the analyses that you want to select",
            help =
            "Select some or all of the samples to export to a "*
            ".csv or .json file for further analysis in higher "*
            "level data reduction software "*
            "such as IsoplotR.",
            action = TUIsubset!
        ),
        "format" => (
            message =
            "c: Export to .csv\n"*
            "j: Export to .json\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Export to a comma-separated variable format with "*
            "samples names as row names, for futher processing "*
            "in Excel, say; or export to a .json format that "*
            "can be opened in an online or offline instance "*
            "of IsoplotRgui.",
            action = Dict(
                "c" => "csv",
                "j" => "json"
            )
        ),
        "csv" => (
            message = "Enter the path and name of the .csv "*
            "file (? for help, x to exit):",
            help = "Provide the file name with or without "*
            "the .csv extension.",
            action = TUIexport2csv
        ),
        "json" => (
            message = "Enter the path and name of the "*
            ".json file (? for help, x to exit):",
            help = "Provide the file name with or without "*
            "the .json extension.",
            action = TUIexport2json
        ),
        "log" => (
            message =
            "Choose an option:\n"*
            "i: Import a session log\n"*
            "e: Export the session log\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Session logs are an easy and useful way to "*
            "save intermediate results, "*
            "save default settings, increase throughput, "*
            "develop FAIR data processing "*
            "chains, and report bugs.",
            action = Dict(
                "i" => "importLog",
                "e" => "exportLog"
            )
        ),
        "importLog" => (
            message = "Enter the path and name of the log "*
            "file (? for help, x to exit):",
            help = "Open a previous log and continue where you left off.",
            action = TUIimportLog!
        ),
        "exportLog" => (
            message = "Enter the path and name of the log "*
            "file (? for help, x to exit):",
            help = "Save the current Plasmatrace so that you "*
            "can replicate your results later",
            action = TUIexportLog
        )
    )    
end

function welcome()
    version = string(pkgversion(@__MODULE__))
    title = " Plasmatrace "*version*" \n"
    width = Base.length(title)-1
    println('-'^width*"\n"*title*'-'^width)
end

function check(ctrl::AbstractDict,action::AbstractString)
    return ctrl["priority"][action] ? "[*]" : ""
end

function TUIinstrument!(ctrl::AbstractDict,
                        response::AbstractString)
    if response=="1"
        ctrl["instrument"] = "Agilent"
    elseif response=="2"
        ctrl["instrument"] = "ThermoFisher"
    else
        return "x"
    end
    return "load"
end

function TUIload!(ctrl::AbstractDict,response::AbstractString)
    ctrl["run"] = load(response,
                       instrument=ctrl["instrument"],
                       head2name=ctrl["head2name"])
    ctrl["priority"]["load"] = false
    ctrl["refresher"]["dname"] = response
    return "xx"
end

function TUImethod!(ctrl::AbstractDict,response::AbstractString)
    methods = _PT["methods"].method
    i = parse(Int,response)
    if i > length(methods)
        return "x"
    else
        ctrl["method"] = methods[i]
    end
    return "columns"
end

function TUIcolumnMessage(ctrl::AbstractDict)
    msg = "Choose from the following list of channels:\n"
    labels = names(getDat(ctrl["run"][1]))
    for i in eachindex(labels)
        msg *= string(i)*". "*labels[i]*"\n"
    end
    msg *= "and select the channels corresponding to "*
    "the following isotopes or their proxies:\n"
    P, D, d = getPDd(ctrl["method"])
    msg *= P *", "* D *", "* d *"\n"
    msg *= "Specify your selection as a "*
    "comma-separated list of numbers:"
    return msg
end

function TUIcolumns!(ctrl::AbstractDict,response::AbstractString)
    labels = names(getDat(ctrl["run"][1]))
    selected = parse.(Int,split(response,","))
    PDd = labels[selected]
    ctrl["channels"] = Dict("d" => PDd[3], "D" => PDd[2], "P" => PDd[1])
    ctrl["priority"]["method"] = false
    if ctrl["method"]=="U-Pb"
        next = "xx"
    else
        next = "iratio"
    end
    return next
end

function TUIiratioMessage(ctrl::AbstractDict)
    msg = "Which isotope is measured as \""*ctrl["channels"]["d"]*"\"?\n"
    isotopes = keys(_PT["iratio"][ctrl["method"]])
    for i in eachindex(isotopes)
        msg *= string(i)*": "*string(isotopes[i])*"\n"
    end
    msg *= "x: Exit\n" * "?: Help"
    return msg
end

function TUIiratio!(ctrl::AbstractDict,response::AbstractString)
    iratios = _PT["iratio"][ctrl["method"]]
    i = parse(Int,response)
    ctrl["mf"] = iratios[i]
    return "xxx"
end

function TUItabulate(ctrl::AbstractDict)
    summary_table = summarise(ctrl["run"])
    println(summary_table)
end

function TUIaddStandardsByPrefix!(ctrl::AbstractDict,
                                  response::AbstractString)
    snames = getSnames(ctrl["run"])
    ctrl["selection"] = findall(contains(response),snames)
    if response in ctrl["refresher"]["prefixes"] # overwrite
        ctrl["refresher"]["prefixes"] = [response]
        ctrl["refresher"]["refmats"] = AbstractString[]
    else # append
        push!(ctrl["refresher"]["prefixes"],response)
    end
    return "refmat"
end

function TUIaddStandardsByNumber!(ctrl::AbstractDict,
                                  response::AbstractString)
    ctrl["selection"] = parse.(Int,split(response,","))
    return "refmat"    
end

function TUIremoveStandardsByNumber!(ctrl::AbstractDict,
                                     response::AbstractString)
    selection = parse.(Int,split(response,","))
    resetStandards!(ctrl["run"],selection)
    return "x"
end

function TUIresetStandards!(ctrl::AbstractDict)
    setStandards!(ctrl["run"],"sample")
    ctrl["refresher"]["prefixes"] = AbstractString[]
    ctrl["refresher"]["refmats"] = AbstractString[]
    return "x"
end

function TUIshowMethods(ctrl::AbstractDict)
    methods = _PT["methods"].method
    msg = ""
    for i in eachindex(methods)
        msg *= string(i)*": "*methods[i]*"\n"
    end
    msg *= "x: Exit\n"*"?: Help"
    return msg
end

function TUIshowRefmats(ctrl::AbstractDict)
    msg = "Which of the following standards did you select?\n"
    standards = collect(keys(_PT["refmat"][ctrl["method"]]))
    for i in eachindex(standards)
        msg *= string(i)*": "*standards[i]*"\n"
    end
    msg *= "x: Exit\n"*"?: Help"
    return msg
end

function TUIsetStandards!(ctrl::AbstractDict,response::AbstractString)
    standards = collect(keys(_PT["refmat"][ctrl["method"]]))
    i = parse(Int,response)
    setStandards!(ctrl["run"],ctrl["selection"],standards[i])
    ctrl["priority"]["standards"] = false
    nr = length(ctrl["refresher"]["refmats"])
    np = length(ctrl["refresher"]["prefixes"])
    if nr < np
        push!(ctrl["refresher"]["refmats"],standards[i])
    end
    return "xxx"
end

function TUIviewer!(ctrl::AbstractDict)
    TUIplotter(ctrl)
    push!(ctrl["chain"],"view")
end

function TUIprocess!(ctrl::AbstractDict)
    groups = unique(getGroups(ctrl["run"]))
    stds = groups[groups.!="sample"]
    ctrl["anchors"] = getAnchor(ctrl["method"],stds)
    println("Fitting blanks...")
    ctrl["blank"] = fitBlanks(ctrl["run"],nb=ctrl["options"]["blank"])
    println("Fractionation correction...")
    ctrl["par"] = fractionation(ctrl["run"],
                                blank=ctrl["blank"],
                                channels=ctrl["channels"],
                                anchors=ctrl["anchors"],
                                nf=ctrl["options"]["drift"],
                                nF=ctrl["options"]["down"],
                                mf=ctrl["mf"],
                                PAcutoff=ctrl["PAcutoff"])
    ctrl["priority"]["process"] = false
    println("Done")
end

function TUInext!(ctrl::AbstractDict)
    ctrl["i"] += 1
    if ctrl["i"]>length(ctrl["run"]) ctrl["i"] = 1 end
    TUIplotter(ctrl)
end

function TUIprevious!(ctrl::AbstractDict)
    ctrl["i"] -= 1
    if ctrl["i"]<1 ctrl["i"] = length(ctrl["run"]) end
    TUIplotter(ctrl)
end

function TUIgoto!(ctrl::AbstractDict,response::AbstractString)
    ctrl["i"] = parse(Int,response)
    if ctrl["i"]>length(ctrl["run"]) ctrl["i"] = 1 end
    if ctrl["i"]<1 ctrl["i"] = length(ctrl["run"]) end
    TUIplotter(ctrl)
    return "x"
end

function TUIplotter(ctrl::AbstractDict)
    samp = ctrl["run"][ctrl["i"]]
    if haskey(ctrl,"channels")
        channels = ctrl["channels"]
    else
        channels = names(samp.dat)[3:end]
    end
    if isnothing(ctrl["blank"]) | isnothing(ctrl["anchors"]) | (samp.group=="sample")
        p = plot(samp,channels,den=ctrl["den"],transformation=ctrl["transformation"])
    else
        if isnothing(ctrl["PAcutoff"])
            par = ctrl["par"]
        else
            analog = isAnalog(samp,channels=ctrl["channels"],
                              cutoff=ctrl["PAcutoff"])
            j = analog ? 1 : 2
            par = ctrl["par"][j]
        end
        p = plot(samp,channels,ctrl["blank"],par,ctrl["anchors"],
                 den=ctrl["den"],transformation=ctrl["transformation"])
    end
    if !isnothing(ctrl["PAcutoff"])
        addPAline!(p,ctrl["PAcutoff"])
    end
    display(p)
end

function addPAline!(p,cutoff::AbstractFloat)
    ylim = Plots.ylims(p)
    if  sqrt(cutoff) < 1.1*ylim[2]
        Plots.plot!(p,collect(Plots.xlims(p)),
                    fill(sqrt(cutoff),2),
                    seriestype=:line,label="",
                    linewidth=2,linestyle=:dash)
    end
end

function TUIratioMessage(ctrl::AbstractDict)
    if haskey(ctrl,"channels")
        channels = collect(values(ctrl["channels"]))
    else
        channels = names(ctrl["run"][1].dat)[3:end]
    end
    msg = "Choose one of the following denominators:\n"
    for i in 1:length(channels)
        msg *= string(i)*": "*channels[i]*"\n"
    end
    msg *= "or\n"
    msg *= "n: No denominator. Plot the raw signals\n"
    msg *= "?: Help"
end

function TUIratios!(ctrl::AbstractDict,response::AbstractString)
    if response=="n"
        ctrl["den"] = nothing
    elseif response=="x"
        return "xx"
    else
        i = parse(Int,response)
        if haskey(ctrl,"channels")
            channels = collect(values(ctrl["channels"]))
        else
            channels = names(ctrl["run"][1].dat)[3:end]
        end
        ctrl["den"] = channels[i]
    end
    TUIplotter(ctrl)
    return "x"
end

function TUIoneAutoBlankWindow!(ctrl::AbstractDict)
    setBwin!(ctrl["run"][ctrl["i"]])
    TUIplotter(ctrl)
end

function TUIoneSingleBlankWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    bwin = string2windows(samp,text=response,single=true)
    setBwin!(samp,bwin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiBlankWindow!(ctrl::AbstractDict,
                                 response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    bwin = string2windows(samp,text=response,single=false)
    setBwin!(samp,bwin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIallAutoBlankWindow!(ctrl::AbstractDict)
    setBwin!(ctrl["run"])
    TUIplotter(ctrl)
end

function TUIallSingleBlankWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        bwin = string2windows(samp,text=response,single=true)
        setBwin!(samp,bwin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiBlankWindow!(ctrl::AbstractDict,
                                 response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        bwin = string2windows(samp,text=response,single=false)
        setBwin!(samp,bwin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneAutoSignalWindow!(ctrl::AbstractDict)
    setSwin!(ctrl["run"][ctrl["i"]])
    TUIplotter(ctrl)
end

function TUIoneSingleSignalWindow!(ctrl::AbstractDict,
                                   response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    swin = string2windows(samp,text=response,single=true)
    setSwin!(samp,swin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiSignalWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    swin = string2windows(samp,text=response,single=false)
    setSwin!(samp,swin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIallAutoSignalWindow!(ctrl::AbstractDict)
    setSwin!(ctrl["run"])
    TUIplotter(ctrl)
end

function TUIallSingleSignalWindow!(ctrl::AbstractDict,
                                   response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,text=response,single=true)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiSignalWindow!(ctrl::AbstractDict,
                                  response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,text=response,single=false)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUItransformation!(ctrl::AbstractDict,
                            response::AbstractString)
    if response=="L"
        ctrl["transformation"] = "log"
    elseif response=="s"
        ctrl["transformation"] = "sqrt"
    else
        ctrl["transformation"] = ""
    end
    TUIplotter(ctrl)
    return "x"
end

function TUIsetNblank!(ctrl::AbstractDict,response::AbstractString)
    ctrl["options"]["blank"] = parse(Int,response)
    return "x"
end

function TUIsetNdrift!(ctrl::AbstractDict,response::AbstractString)
    ctrl["options"]["drift"] = parse(Int,response)
    return "x"    
end

function TUIsetNdown!(ctrl::AbstractDict,response::AbstractString)
    ctrl["options"]["down"] = parse(Int,response)
    return "x"    
end

function TUIsetmf!(ctrl::AbstractDict,response::AbstractString)
    ctrl["mf"] = response=="" ? nothing : parse(Float64,response)
    return "x"
end

function TUIRefMatTab(ctrl::AbstractDict)
    for (key, value) in _PT["refmat"][ctrl["method"]]
        print(key)
        print(": t=")
        print(value.t[1])
        print(" Ma, y0=")
        print(value.y0[1])
        print("\n")
    end
    return "x"
end

function TUIPAlist(ctrl::AbstractDict)
    snames = getSnames(ctrl["run"])
    for i in eachindex(snames)
        dat = getDat(ctrl["run"][i],ctrl["channels"])
        maxval = maximum(Matrix(dat))
        formatted = @sprintf("%.*e", 3, maxval)
        println(formatted*" ("*snames[i]*")")
    end
    return "x"
end

function TUIsetPAcutoff!(ctrl::AbstractDict,response::AbstractString)
    cutoff = tryparse(Float64,response)
    ctrl["PAcutoff"] = cutoff
    return "xx"
end

function TUIclearPAcutoff!(ctrl::AbstractDict)
    ctrl["PAcutoff"] = nothing
    return "xx"
end

function TUIaddRefMat!(ctrl::AbstractDict,response::AbstractString)
    setReferenceMaterials!(response)
    return "x"
end

function TUIhead2name!(ctrl::AbstractDict,response::AbstractString)
    ctrl["head2name"] = response=="h"
    return "x"
end

function TUIimportLog!(ctrl::AbstractDict,response::AbstractString)
    history = CSV.read(response,DataFrame)
    ctrl["history"] = DataFrame(task=String[],action=String[])
    for row in eachrow(history)
        try
            dispatch!(ctrl,key=row[1],response=row[2])
        catch e
            println(e)
        end
    end
    return nothing
end

function TUIexportLog(ctrl::AbstractDict,response::AbstractString)
    pop!(ctrl["history"])
    pop!(ctrl["history"])
    CSV.write(response,ctrl["history"])
    return "xx"
end

function TUIsubset!(ctrl::AbstractDict,response::AbstractString)
    if response=="a"
        ctrl["selection"] = 1:length(ctrl["run"])
    elseif response=="s"
        ctrl["selection"] = findall(contains("sample"),getGroups(ctrl["run"]))
    elseif response=="x"
        return "x"
    else
        ctrl["selection"] = findall(contains(response),getSnames(ctrl["run"]))
    end
    return "format"
end

function TUIexport2csv(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],channels=ctrl["channels"],
                    pars=ctrl["par"],blank=ctrl["blank"],
                    PAcutoff=ctrl["PAcutoff"])
    fname = splitext(response)[1]*".csv"
    CSV.write(fname,ratios[ctrl["selection"],:])
    return "xxx"
end

function TUIexport2json(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],channels=ctrl["channels"],
                    pars=ctrl["par"],blank=ctrl["blank"],
                    PAcutoff=ctrl["PAcutoff"])
    fname = splitext(response)[1]*".json"
    export2IsoplotR(fname,ratios[ctrl["selection"],:],ctrl["method"])
    return "xxx"
end

function TUIrefresh!(ctrl::AbstractDict)
    R = ctrl["refresher"]
    TUIload!(ctrl,R["dname"])
    snames = getSnames(ctrl["run"])
    for i in eachindex(R["prefixes"])
        ctrl["selection"] = findall(contains(R["prefixes"][i]),snames)
        setStandards!(ctrl["run"],ctrl["selection"],R["refmats"][i])
    end
    TUIprocess!(ctrl)
    return nothing
end
