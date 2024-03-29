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
        "mf" => nothing
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

function dispatch!(ctrl::AbstractDict;key=nothing,response=nothing,verbose=false)
    if (verbose)
        println(ctrl["chain"])
    end
    if isnothing(key) key = ctrl["chain"][end] end
    (message,help,action) = tree(key,ctrl)
    if isa(message,Function)
        println("\n"*message(ctrl))
    else
        println("\n"*message)
    end
    if isnothing(response) response = readline() end
    if response == "?"
        println(help)
        next = nothing
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

function tree(key::AbstractString,ctrl::AbstractDict)
    branches = Dict(
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
            "x: Exit\n"*
            "?: Help",
            help = "This is the top-level menu. Asterisks (*) mark compulsory steps.",
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
                "x" => "x"
            )
        ),
        "instrument" => (
            message =
            "1: Agilent\n"*
            "x: Exit\n"*
            "?: Help",
            help = "Choose a file format. Email us if you don't find your instrument in this list.",
            action = TUIinstrument!
        ),
        "load" => (
            message = "Enter the full path of the data directory (? for help, x to exit):",
            help = "Plasmatrace will read all the files in this directory. "*
            "You don't need to select the files, just the directory.",
            action = TUIload!,
        ),
        "method" => (
            message =
            "1: Lu-Hf\n"*
            "x: Exit\n"*
            "?: Help",
            help = "Choose a geochronometer. Email us if you can't find your chosen method.",
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
            "Plasmatrace does not know which data label corresponds to which isotope. "*
            "Sometimes one non-radiogenic isotope is used as a proxy for another. "*
            "This must be specified for the proxy conversion to work.",
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
            "Note that secondary reference materials should be treated as regular samples.",
            action = Dict(
                "t" => TUItabulate,
                "p" => "addStandardsByPrefix",
                "n" => "addStandardsByNumber",
                "N" => "removeStandardsByNumber",
                "r" => TUIresetStandards!,
                "x" => "x"
            )
        ),
        "addStandardsByPrefix" => (
            message = "Specify the prefix of the standard (? for help, x to exit):",
            help =
            "For example, suppose that Plesovice zircon reference materials are "*
            "named STDCZ01, STDCZ02, ..., then you can select all the standards "*
            "by entering STDCZ here. Enter 'x' to go up one level and tabulate the "*
            "sample if you forgot the exact prefix of your standards.",
            action = TUIaddStandardsByPrefix!
        ),
        "addStandardsByNumber" => (
            message =
            "Select the standards as a comma-separated list of numbers "*
            "(? for help, x to exit):",
            help =
            "For example, suppose that the analyses are labelled as "*
            "G001, G002, ..., then it is not possible to identify the standards by "*
            "prefix, but you can still select them by sequence number (e.g., 1,2,8,9,15,16,...).",
            action = TUIaddStandardsByNumber!
        ),
        "removeStandardsByNumber" => (
            message =
            "Select the standards as a comma-separated list of numbers "*
            "(? for help, x to exit):",
            help =
            "'bad' standards can be removed one-by-one, by specifying their number. "*
            "Enter 'x' to go up one level and tabulate the sample if you forgot the "*
            "exact prefix of your standards.",
            action = TUIremoveStandardsByNumber!
        ),
        "refmat" => (
            message = TUIshowRefmats,
            help =
            "Even though you may have specified the prefix of your reference materials, "*
            "Plasmatrace still does not know which standard this refers to. That information "*
            "can be specified here. If you do not find your reference material in this list, "*
            "then you can either specify your own reference material under 'options' in the "*
            "top menu, or you can email us to add the material to the software.",
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
            "x: Exit\n"*
            "?: Help",
            help =
            "It is useful to view all the samples in your analytical sequence "*
            "at least once, to modify blank and signal windows or checking the "*
            "fit to the standards.",
            action = Dict(
                "n" => TUInext!,
                "p" => TUIprevious!,
                "g" => "goto",
                "t" => TUItabulate,
                "r" => "setDen",
                "b" => "Bwin",
                "s" => "Swin",
                "x" => "x"
            )
        ),
        "goto" => (
            message = "Enter the number of the sample to plot (? for help, x to exit):",
            help = "Jump to a specific analysis.",
            action = TUIgoto!
        ),
        "setDen" => (
            message = TUIratioMessage,
            help =
            "Plot the ratios of the channels relative to a common denominator. "*
            "Zero values for the denominator are omitted.",
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
            "Specify the blank (background signal) as pairs of time stamps (in seconds) "*
            "or trust Plasmatrace to choose the blank windows automatically. "*
            "The blanks of all the analyses (samples + blanks) will be combined and "*
            "interpolated under the signal.",
            action = Dict(
                "a" => TUIoneAutoBlankWindow!,
                "s" => "oneSingleBlankWindow",
                "m" => "oneMultiBlankWindow",
                "A" => TUIallAutoBlankWindow!,
                "S" => "allSingleBlankWindow",
                "M" => "allMultiBlankWindow",
                "x" => "x"
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
            "or trust Plasmatrace to choose the signal windows automatically. "*
            "The signals of the reference materials are used to define the "*
            "drift and fractionation corrections, which are then applied to the samples.",
            action = Dict(
                "a" => TUIoneAutoSignalWindow!,
                "s" => "oneSingleSignalWindow",
                "m" => "oneMultiSignalWindow",
                "A" => TUIallAutoSignalWindow!,
                "S" => "allSingleSignalWindow",
                "M" => "allMultiSignalWindow",
                "x" => "x"
            )
        ),
        "oneSingleBlankWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds)\n"*
            "Type '?' for help.",
            help =
            "Specify the start and end point of the blank window "*
            "as a comma-separated pair of numbers. For example: 0,20 marks "*
            "a blank window from 0 to 20 seconds.",
            action = TUIoneSingleBlankWindow!
        ),
        "oneMultiBlankWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds)\n"*
            "Type '?' for help.",
            help =
            "Specify the start and end points of the blank window "*
            "as a comma-separated list of bracketed pairs "*
            " of numbers. For example: (0,20),(25,30) marks a two-part "*
            "selection window from 0 to 20s, and from 25 to 30s.",
            action = TUIoneMultiBlankWindow!
        ),
        "allSingleBlankWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds)\n"*
            "Type 'h' for help.",
            help =
            "Specify the start and end point of the blank windows "*
            "as a comma-separated pair of numbers. For example: 0,20 marks "*
            "a blank window from 0 to 20 seconds.",
            action = TUIallSingleBlankWindow!
        ),
        "allMultiBlankWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds)\n"*
            "Type 'h' for help.",
            help =
            "Specify the start and end points of the blank windows "*
            "as a comma-separated list of bracketed pairs "*
            " of numbers. For example: (0,20),(25,30) marks a two-part "*
            "selection window from 0 to 20s, and from 25 to 30s.",
            action = TUIallMultiBlankWindow!
        ),
        "oneSingleSignalWindow" => (
            message =
            "Enter the start and end point of the selection window (in seconds)\n"*
            "Type 'h' for help.",
            help =
            "Specify the start and end points of the signal window "*
            "as a comma-separated pair of numbers. For example: 30,60 marks "*
            "a signal window from 30 to 60 seconds.",
            action = TUIoneSingleSignalWindow!
        ),
        "oneMultiSignalWindow" => (
            message =
            "Enter the start and end points of the multi-part "*
            "selection window (in seconds)\n"*
            "Type 'h' or help.",
            help =
            "Specify the start and end points of the signal window "*
            "as a comma-separated list of bracketed pairs "*
            "of numbers. For example: (40,45),(50,60) marks a two-part "*
            "signal window from 40 to 45s, and from 50 to 60s.",
            action = TUIoneMultiSignalWindow!
        ),
        "allSingleSignalWindow" => (
            message =
            "Enter the start and end point of the selection windows (in seconds)\n"*
            "Type 'h' for help.",
            help =
            "Specify the start and end points of the signal windows "*
            "as a comma-separated pair of numbers. For example: 30,60 marks "*
            "a signal window from 30 to 60 seconds.",
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
            "h: Set the polynomial order of the down hole fractionation correction\n"*
            "f: Fix or fit the fractionation factor\n"*
            "p: Subset the data by P/A cutoff\n"*
            "r: Define new reference materials\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Advanced settings to override the default behaviour of Plasmatrace. "*
            "See the individual options for further information.",
            action = Dict(
                "b" => "setNblank",
                "d" => "setNdrift",
                "h" => "setNdown",
                "f" => "setmf",
                "p" => "setPAcutoff",
                "r" => "addRefMat",
                "x" => "x"
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
            (isnothing(ctrl["mf"]) ? "fitted" : ("fixed at "*string(ctrl["mf"])))*
            ", ? for help, x to exit)",
            help =
            "Clicking [Enter] tells Plasmatrace to estimate the mass fractionation "*
            "factor by forcing the y-intercept of an inverse isochron to coincide with "*
            "a prescribed value. This works well for reference materials that form a "*
            "well defined isochron. For reference materials that are very radiogenic, "*
            "it is often better to stick with the default value, which is 1 if the ."*
            "non-radiogenic isochron isotope is measured directly, or the IUPAC recommended "*
            "ratio if the non-radiogenic isotope is measured by proxy",
            action = TUIsetmf!
        ),
        "setPAcutoff" => (
            message =
            "p: Select samples measured in pulse mode\n"*
            "a: Select samples measured in analog mode\n"*
            "b: Select both pulse and analog samples\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Subset samples that are measured in pulse mode "*
            "(all relevant signals are below a specified cutoff) "*
            "or in analog mode (above the cutoff)\n",
            action = Dict(
                "p" => TUIpulse!,
                "a" => TUIanalog!,
                "b" => TUIpulseanalog!,
                "x" => "xx"
            )
        ),
        "addRefMat" => (
            message =
            "p: Enter the path to the standards file\n"*
            "x: Exit\n"*
            "?: Help\n",
            help =
            "Add new isotopic reference materials to Plasmatrace by specifying "*
            "the path to a .csv file that is formatted as follows:\n\n"*
            "method,name,t,y0\n"*
            "Lu-Hf,Hogsbo,1029,3.55\n"*
            "Lu-Hf,BP,1745,3.55\n\n"*
            "where 't' is the age of the sample and 'y0' is the "*
            "y-intercept of the inverse isochron.\n",
            action = Dict(
                "p" => TUIaddRefMat!,
                "x" => "x"
            )
        ),
        "export" => (
            message =
            "a: All analyses\n"*
            "s: Samples only (no standards)\n"*
            "x: Exit\n"*
            "?: Help\n"*
            "or enter the prefix of the analyses that you want to select",
            help =
            "Select some or all of the samples to export to a .csv or .json "*
            "file for further analysis in higher level data reduction software "*
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
            "Export to a comma-separated variable format with samples names "*
            "as row names, for futher processing in Excel, say; or export to"*
            "a .json format that can be opened in an online or "*
            "offline instance of IsoplotRgui.",
            action = Dict(
                "c" => "csv",
                "j" => "json",
                "x" => "xx"
            )
        ),
        "csv" => (
            message = "Enter the path and name of the .csv file (? for help, x to exit):",
            help = "Provide the file name with or without the .csv extension.",
            action = TUIexport2csv
        ),
        "json" => (
            message = "Enter the path and name of the .json file (? for help, x to exit):",
            help = "Provide the file name with or without the .json extension.",
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
            "Session logs are an easy and useful way to save intermediate results, "*
            "save default settings, increase throughput, develop FAIR data processing "*
            "chains, and report bugs.",
            action = Dict(
                "i" => "importLog",
                "e" => "exportLog",
                "x" => "x"
            )
        ),
        "importLog" => (
            message = "Enter the path and name of the log file (? for help, x to exit):",
            help = "Open a previous log and continue where you left off.",
            action = TUIimportLog!
        ),
        "exportLog" => (
            message = "Enter the path and name of the log file (? for help, x to exit):",
            help = "Save the current Plasmatrace so that you can replicate your results later",
            action = TUIexportLog
        )
    )
    return branches[key]
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

function TUIinstrument!(ctrl::AbstractDict,response::AbstractString)
    if response=="1"
        ctrl["instrument"] = "Agilent"
    else
        return "x"
    end
    return "load"
end

function TUIload!(ctrl::AbstractDict,response::AbstractString)
    ctrl["run"] = load(response,instrument=ctrl["instrument"])
    ctrl["priority"]["load"] = false
    return "xx"
end

function TUImethod!(ctrl::AbstractDict,response::AbstractString)
    if response=="1"
        ctrl["method"] = "LuHf"
    else
        return "x"
    end
    return "columns"
end

function TUIcolumnMessage(ctrl::AbstractDict)
    msg = "Choose from the following list of channels:\n"
    labels = names(ctrl["run"][1].dat)[3:end]
    for i in eachindex(labels)
        msg *= string(i)*". "*labels[i]*"\n"
    end
    msg *= "and select the channels corresponding to "*
    "the following isotopes or their proxies:\n"
    if ctrl["method"]=="LuHf"
        msg *= "176Lu, 176Hf, 177Hf\n"
    end
    msg *= "Specify your selection as a "*
    "comma-separated list of numbers:\n"
    return msg
end

function TUIcolumns!(ctrl::AbstractDict,response::AbstractString)
    labels = names(ctrl["run"][1].dat)[3:end]
    selected = parse.(Int,split(response,","))
    PDd = labels[selected]
    next = "xx"
    if ctrl["method"]=="LuHf"
        ctrl["channels"] = Dict("d" => PDd[3], "D" => PDd[2], "P" => PDd[1])
        ctrl["priority"]["method"] = false
        next = "iratio"
    end
    return next
end

function TUIiratioMessage(ctrl::AbstractDict)
    if ctrl["method"]=="LuHf"
        msg = "Which Hf-isotope is measured as \""*ctrl["channels"]["d"]*"\"?\n"*
        "1: 174Hf\n"*
        "2: 177Hf\n"*
        "3: 178Hf\n"*
        "4: 179Hf\n"*
        "5: 180Hf\n"
    end
    msg *= "?: Help\n"
    return msg
end

function TUIiratio!(ctrl::AbstractDict,response::AbstractString)
    if ctrl["method"]=="LuHf"
        if response=="1"
            ctrl["mf"] = _PT["iratio"]["Hf174Hf177"]
        elseif response=="3"
            ctrl["mf"] = _PT["iratio"]["Hf178Hf177"]
        elseif response=="4"
            ctrl["mf"] = _PT["iratio"]["Hf179Hf177"]
        elseif response=="5"
            ctrl["mf"] = _PT["iratio"]["Hf180Hf177"]
        else # "2"
            ctrl["mf"] = nothing
        end
    end
    return "xxx"
end

function TUItabulate(ctrl::AbstractDict)
    summarise(ctrl["run"])
end

function TUIaddStandardsByPrefix!(ctrl::AbstractDict,response::AbstractString)
    snames = getSnames(ctrl["run"])
    ctrl["selection"] = findall(contains(response),snames)
    return "refmat"
end

function TUIaddStandardsByNumber!(ctrl::AbstractDict,response::AbstractString)
    ctrl["selection"] = parse.(Int,split(response,","))
    return "refmat"    
end

function TUIremoveStandardsByNumber!(ctrl::AbstractDict,response::AbstractString)
    selection = parse.(Int,split(response,","))
    resetStandards!(ctrl["run"],selection)
    return "x"
end

function TUIresetStandards!(ctrl::AbstractDict)
    setStandards!(ctrl["run"],"sample")
    return "x"
end

function TUIshowRefmats(ctrl::AbstractDict)
    if ctrl["method"]=="LuHf"
        msg = "Which of the following standards did you select?\n"*
        "1: Hogsbo\n"*
        "2: BP\n"*
        "x: Exit"*
        "?: Help"
    end
    return msg
end

function TUIsetStandards!(ctrl::AbstractDict,response::AbstractString)
    if ctrl["method"]=="LuHf"
        if response=="1"
            setStandards!(ctrl["run"],ctrl["selection"],"Hogsbo")
        elseif response=="2"
            setStandards!(ctrl["run"],ctrl["selection"],"BP")
        end
    end
    ctrl["priority"]["standards"] = false
    return "xxx"
end

function TUIviewer!(ctrl::AbstractDict)
    TUIplotter(ctrl)
    push!(ctrl["chain"],"view")
end

function TUIprocess!(ctrl::AbstractDict)
    println("Fitting blanks...")
    ctrl["blank"] = fitBlanks(ctrl["run"],n=ctrl["options"]["blank"])
    groups = unique(getGroups(ctrl["run"]))
    stds = groups[groups.!="sample"]
    ctrl["anchors"] = getAnchor(ctrl["method"],stds)
    println("Fractionation correction...")
    ctrl["par"] = fractionation(ctrl["run"],blank=ctrl["blank"],
                                channels=ctrl["channels"],
                                anchors=ctrl["anchors"],mf=ctrl["mf"])
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
    i = ctrl["i"]
    samp = ctrl["run"][i]
    if haskey(ctrl,"channels")
        channels = ctrl["channels"]
    else
        channels = names(samp.dat)[3:end]
        println(channels)
    end
    p = plot(samp,channels,den=ctrl["den"])
    if samp.group!="sample"
        plotFitted!(p,samp,ctrl["par"],ctrl["blank"],
                    ctrl["channels"],ctrl["anchors"],den=ctrl["den"])
    end
    display(p)
end

function TUIratioMessage(ctrl::AbstractDict)
    if haskey(ctrl,"channels")
        channels = collect(values(ctrl["channels"]))
    else
        channels = names(ctrl["run"][ctrl["i"]].dat)[3:end]
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
            channels = collect(keys(ctrl["channels"]))
        else
            channels = names(ctrl["run"][ctrl["i"]].dat)[3:end]
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

function TUIoneSingleBlankWindow!(ctrl::AbstractDict,response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    bwin = string2windows(samp,text=response,single=true)
    setBwin!(samp,bwin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiBlankWindow!(ctrl::AbstractDict,response::AbstractString)
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

function TUIallSingleBlankWindow!(ctrl::AbstractDict,response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        bwin = string2windows(samp,text=response,single=true)
        setBwin!(samp,bwin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiBlankWindow!(ctrl::AbstractDict,response::AbstractString)
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

function TUIoneSingleSignalWindow!(ctrl::AbstractDict,response::AbstractString)
    samp = ctrl["run"][ctrl["i"]]
    swin = string2windows(samp,text=response,single=true)
    setSwin!(samp,swin)
    TUIplotter(ctrl)
    return "xx"
end

function TUIoneMultiSignalWindow!(ctrl::AbstractDict,response::AbstractString)
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

function TUIallSingleSignalWindow!(ctrl::AbstractDict,response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,text=response,single=true)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
    return "xx"
end

function TUIallMultiSignalWindow!(ctrl::AbstractDict,response::AbstractString)
    for i in eachindex(ctrl["run"])
        samp = ctrl["run"][i]
        swin = string2windows(samp,text=response,single=false)
        setSwin!(samp,swin)
    end
    TUIplotter(ctrl)
    return "xx"
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

function TUIpulse!()
    println("TODO")
    return "x"
end

function TUIanalog!()
    println("TODO")
    return "x"
end

function TUIpulseanalog!()
    println("TODO")
    return "x"
end

function TUIaddRefMat!()
    println("TODO")
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
    run = ctrl["run"]
    if response=="a"
        ctrl["selection"] = 1:length(run)
    elseif response=="s"
        ctrl["selection"] = findall(contains("sample"),getGroups(run))
    elseif response=="x"
        return "x"
    else
        ctrl["selection"] = findall(contains(response),getSnames(run))
    end
    return "format"
end

function TUIexport2csv(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],channels=ctrl["channels"],
                    pars=ctrl["par"],blank=ctrl["blank"])
    fname = splitext(response)[1]*".csv"
    CSV.write(fname,ratios[ctrl["selection"],:])
    return "xxx"
end

function TUIexport2json(ctrl::AbstractDict,response::AbstractString)
    ratios = averat(ctrl["run"],channels=ctrl["channels"],
                    pars=ctrl["par"],blank=ctrl["blank"])
    fname = splitext(response)[1]*".json"
    export2IsoplotR(fname,ratios[ctrl["selection"],:],ctrl["method"])
    return "xxx"
end
