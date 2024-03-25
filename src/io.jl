function read_file(file::AbstractString; instrument::AbstractString = "Agilent")
    if instrument == "Agilent"
        sample_name, analysis_name, date_time, data = read_agilent(file)
        blank_window = autoWindow(data[:, 2:end]; blank = true)
        signal_window = autoWindow(data[:, 2:end]; blank = false)
    else
        PTerror("unknownInstrument")
    end
    return Sample(
        sample_name,
        analysis_name,
        date_time,
        data,
        blank_window,
        signal_window,
        "sample",
    )
end

function load(directory_name::AbstractString; instrument::AbstractString = "Agilent")
    files = glob(get_file_extension(instrument), directory_name)
    analyses = Vector{Sample}(undef, length(files))
    date_times = Vector{DateTime}(undef, length(files))
    @threads for i in eachindex(files)
        try
            analyses[i] = read_file(files[i]; instrument = instrument)
            date_times[i] = analyses[i].date_time
        catch
            println("Failed to read " * files[i])
        end
    end
    order = sortperm(date_times)
    analyses = analyses[order]
    @threads for i in eachindex(analyses)
        analyses[i].data.run_time_hours .+=
            (Dates.value(analyses[i].date_time - date_times[begin]) / hour_milliseconds)
    end
    return analyses
end
export load

function read_agilent(
    file::AbstractString,
    date_time_format::DateFormat = Dates.DateFormat("d/m/Y H:M:S"),
)
    lines = split(readuntil(file, "Time "), "\n")
    # read header
    analysis_name = split(lines[1], "\\")[end][begin:(end - 2)]
    sample_name = rstrip(analysis_name[begin:(findlast("-", analysis_name)[1] - 1)])
    date_time = rstrip(
        lines[3][(findfirst(":", lines[3])[1] + 2):(findfirst("using", lines[3])[1] - 1)],
    )
    date_time = Dates.DateTime(date_time, date_time_format)
    if Dates.Year(date_time) < Dates.Year(2000)
        date_time += Dates.Year(2000)
    end
    #read data
    data = CSV.read(
        file,
        DataFrame;
        header = 4,
        skipto = 5,
        footerskip = 3,
        ignoreemptyrows = true,
        normalizenames = true,
        delim = ',',
    )
    rename!(data, "Time_Sec_" => "local_time_seconds")
    insertcols!(data, 2, "run_time_hours" => data.local_time_seconds ./ 3600)

    return sample_name, analysis_name, date_time, data
end

function get_file_extension(instrument)
    if instrument == "Agilent"
        return "*.csv"
    else
        PTerror("unknownInstrument")
    end
end
