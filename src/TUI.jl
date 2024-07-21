function PT(logbook="")
    TUIwelcome()
    ctrl = Dict(
        "priority" => Dict("load" => true, "method" => true,
                           "standards" => true, "glass" => true,
                           "process" => true),
        "history" => DataFrame(task=String[],action=String[]),
        "chain" => ["top"],
        "i" => 1,
        "den" => nothing,
        "head2name" => true,
        "instrument" => "",
        "dname" => "",
        "method" => "",
        "channels" => Dict(),
        "standards" => AbstractString[],
        "glass" => AbstractString[],
        "options" => Dict("blank" => 2, "drift" => 1, "down" => 1),
        "PAcutoff" => nothing,
        "blank" => nothing,
        "par" => nothing,
        "cache" => nothing,
        "transformation" => "sqrt",
        "template" => false
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
            "r: Read data files"*TUIcheck(ctrl,"load")*"\n"*
            "m: Specify the method"*TUIcheck(ctrl,"method")*"\n"*
            "t: Tabulate the samples\n"*
            "s: Mark mineral standards"*TUIcheck(ctrl,"standards")*"\n"*
            "g: Mark reference glasses"*TUIcheck(ctrl,"glass")*"\n"*
            "v: View and adjust each sample\n"*
            "p: Process the data"*TUIcheck(ctrl,"process")*"\n"*
            "e: Export the results\n"*
            "l: Logs and templates\n"*
            "o: Options\n"*
            "R: Refresh\n"*
            "x: Exit\n"*
            "?: Help",
            help = "This is the top-level menu. Asterisks (*) "*
            "mark compulsory steps. Refresh reloads the data directory "*
            "and only works if the asterisks are gone.",
            action = Dict(
                "r" => TUIread,
                "m" => "method",
                "t" => TUItabulate,
                "s" => "standards",
                "g" => "glass",
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
        "standards" => (
            message =
            "a: Add a mineral standard\n"*
            "r: Remove mineral standards\n"*
            "l: List the available mineral standards\n"*
            "t: Tabulate all the samples\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Choose one or more primary reference materials. "*
            "Note that secondary reference materials should be "*
            "treated as regular samples.",
            action = Dict(
                "a" => "chooseStandard",
                "r" => "removeStandard",
                "l" => TUIrefmatTab,
                "t" => TUItabulate
            )
        ),
        "chooseStandard" => (
            message = TUIchooseStandardMessage,
            help =
            "If you do not find your mineral standard in this list, "*
            "then you can either specify your own reference "*
            "material under 'options' in the top menu, or "*
            "you can email us to add the material to the software.",
            action = TUIchooseStandard!
        ),
        "addStandardGroup" => (
            message =
            "p: Select samples by prefix\n"*
            "n: Select samples by number\n"*
            "t: Tabulate all the samples\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Select samples to label as primary standards, either "*
            "by specifying the first few characters of their name, "*
            "or by providing a comma-separated list of numbers. "*
            "Enter 't' to remind yourself of the names and "*
            "order of the samples.",
            action = Dict(
                "p" => "addStandardsByPrefix",
                "n" => "addStandardsByNumber",
                "t" => TUItabulate
            )
        ),
        "addStandardsByPrefix" => (
            message = TUIaddByPrefixMessage,
            help =
            "For example, suppose that Plesovice zircon reference "*
            "materials are named STDCZ01, STDCZ02, ..., then you can "*
            "select all the standards by entering STDCZ here. "*
            "Enter 'x' to go up one level and tabulate the "*
            "sample if you forgot the exact prefix of your standards.",
            action = TUIaddStandardsByPrefix!
        ),
        "addStandardsByNumber" => (
            message = TUIaddByNumberMessage,
            help =
            "For example, suppose that the analyses are labelled as "*
            "G001, G002, ..., then it is not possible to identify "*
            "the standards by prefix, but you can still select them "*
            "by sequence number (e.g., 1,2,8,9,15,16,...).",
            action = TUIaddStandardsByNumber!
        ),
        "removeStandard" => (
            message =
            "a: Remove all standards\n"*
            "s: Remove selected standards\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Remove or reset the samples that are marked as primary standards.",
            action = Dict(
                "a" => TUIremoveAllStandards!,
                "s" => "removeStandardsByNumber"
            )
        ),
        "removeStandardsByNumber" => (
            message =
            "Select the reference materials as a comma-separated list of numbers "*
            "(? for help, x to exit):",
            help =
            "Select the samples that are to be removed as primary "*
            "standards by providing a list of comma separated numbers "*
            "(e.g., 1,2,8,9,15,16,...).",
            action = TUIremoveStandardsByNumber!
        ),
        "glass" => (
            message =
            "a: Add a reference glass\n"*
            "r: Remove reference glasses\n"*
            "l: List the available reference glasses\n"*
            "t: Tabulate all the samples\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Choose one or more reference glasses. These are used "*
            "to determine the mass dependent isotope fractionation factor.",
            action = Dict(
                "a" => "chooseGlass",
                "r" => "removeGlass",
                "l" => TUIglassTab,
                "t" => TUItabulate
            )
        ),
        "chooseGlass" => (
            message = TUIchooseGlassMessage,
            help =
            "If you do not find your reference glass in this list, "*
            "then you can either specify your own under 'options' in "*
            "the top menu, or you can email us to add the material to the software.",
            action = TUIchooseGlass!
        ),
        "addGlassGroup" => (
            message =
            "p: Select analyses by prefix\n"*
            "n: Select analyses by number\n"*
            "t: Tabulate all the analyses\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Select samples to label as reference glasses, either "*
            "by specifying the first few characters of their name, "*
            "or by providing a comma-separated list of numbers. "*
            "Enter 't' to remind yourself of the names and "*
            "order of the analyses.",
            action = Dict(
                "p" => "addGlassByPrefix",
                "n" => "addGlassByNumber",
                "t" => TUItabulate
            )
        ),
        "addGlassByPrefix" => (
            message = TUIaddByPrefixMessage,
            help =
            "For example, suppose that NIST-612 reference glasses "*
            "are named GLASS01, GLASS02, ..., then you can "*
            "select all the standards by entering GLASS here. "*
            "Enter 'x' to go up one level and tabulate the "*
            "sample if you forgot the exact prefix of your glasses."*
            "Note that NIST glass is only used to determine chemical "*
            "concentrations and mass fractionation factors, but is "*
            "NOT used as an isotopic ratio standard. Conversely, "*
            "minerals are only used as isotopic ratio standards "*
            "but not as concentration standards. Use both to get the "*
            "best results.",
            action = TUIaddGlassByPrefix!
        ),
        "addGlassByNumber" => (
            message = TUIaddByPrefixMessage,
            help =
            "For example, suppose that the analyses are labelled as "*
            "G001, G002, ..., then it is not possible to identify "*
            "the glasses by prefix, but you can still select them "*
            "by sequence number (e.g., 1,2,8,9,15,16,...).",
            action = TUIaddGlassByNumber!
        ),
        "removeGlass" => (
            message =
            "a: Remove all glass measurements\n"*
            "s: Remove selected analyses\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Unlabel the analyses that are marked as reference glass.",
            action = Dict(
                "a" => TUIremoveAllGlass!,
                "s" => "removeGlassByNumber"
            )
        ),
        "removeGlassByNumber" => (
            message =
            "Select the glass analyses as a comma-separated list of numbers "*
            "(? for help, x to exit):",
            help =
            "Select the samples that are to be removed as reference "*
            "glass by providing a list of comma separated numbers "*
            "(e.g., 1,2,8,9,15,16,...).",
            action = TUIremoveGlassByNumber!
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
            "d: Choose a data transformation\n"*
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
                "d" => "transformation"
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
            "h: Set the polynomial order of the down hole fractionation correction\n"*
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
                "p" => "PA",
                "l" => TUIrefmatTab,
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
            "o: Open a template\n"*
            "s: Save a template\n"*
            "x: Exit\n"*
            "?: Help",
            help =
            "Session logs are an easy and useful way to "*
            "save intermediate results, increase throughput, "*
            "develop FAIR data processing chains, and report bugs.\n"*
            "Methods are slimmed down session logs, which save "*
            "default settings whilst omitting sample-specific details.",
            action = Dict(
                "i" => "importLog",
                "e" => "exportLog",
                "o" => "openMethod",
                "s" => "saveMethod"
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
            help = "Save the current Plasmatrace session so that you "*
            "can replicate your results later",
            action = TUIexportLog
        ),
        "openMethod" => (
            message = "Enter the path and name of the template "*
            "file (? for help, x to exit):",
            help = "Open default settings in a template file to avoid "*
            "repetitive entry of the method details.",
            action = TUIopenMethod!
        ),
        "saveMethod" => (
            message = "Enter the path and name of the template "*
            "file (? for help, x to exit):",
            help = "Save the current Plasmatrace method for use "*
            "in a future session.",
            action = TUIsaveMethod
        )
    )    
end
