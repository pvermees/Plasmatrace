function read_file(file::AbstractString; instrument::AbstractString = "Agilent")
    if instrument == "Agilent"
        sample_name, analysis_name, date_time, data = read_agilent(file)
        blank_window = autoWindow(data[:, 2:end]; blank = true)
        signal_window = autoWindow(data[:, 2:end]; blank = false)
    else
        PTerror("unknownInstrument")
    end
    return Sample(sample_name, analysis_name, date_time, data, blank_window, signal_window, "sample")
end

function load(directory_name::AbstractString; instrument::AbstractString = "Agilent")
    files = glob(get_file_extension(instrument), directory_name)
    analyses = Vector{Sample}(undef, length(files))
    date_times = Vector{DateTime}(undef, length(files))
    @threads for i in eachindex(files)
        try
            analyses[i] = read_file(files[i], instrument = instrument)
            date_times[i] = analyses[i].date_time
        catch
            println("Failed to read " * files[i])
        end
    end
    order = sortperm(date_times)
    sorted_analyses = analyses[order]
    sorted_date_times = date_times[order]
    dt = sorted_date_times .- sorted_date_times[1]
    runtime = Dates.value.(dt) ./ hour_seconds
    for i in eachindex(sorted_analyses)
        analysis = sorted_analyses[i]
        analysis.data[:, 1] = analysis.data[:, 2] ./ hour_seconds .+ runtime[i]
    end
    return sorted_analyses
end
export load

function read_agilent(
    file::AbstractString,
    date_time_format::DateFormat = Dates.DateFormat("d/m/Y H:M:S"),
)
    f = open(file, "r")
    lines = readlines(f)
    # read header
    analysis_name = split(lines[1], "\\")[end][begin:(end - 2)]
    sample_name = rstrip(analysis_name[begin:(findlast("-", analysis_name)[1] - 1)])
    date_time = lines[3][(findfirst(":", lines[3])[1] + 2):(findlast(":", lines[3])[1] + 2)]
    date_time = Dates.DateTime(date_time, date_time_format)
    if Dates.Year(date_time) < Dates.Year(2000)
        date_time += Dates.Year(2000)
    end
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
    rename!(data, "Time_Sec_" => "run_time")

    # @time labels = split(lines[4], ",")

    # # read signals
    # @time nr = size(lines, 1)
    # @time measurements = mapreduce(vcat, lines[5:(nr - 3)]) do s
    #     return (parse.(Float64, split(s, ",")))'
    # end
    # @time labels = ["Run Time [hours]"; labels]
    # @time data = DataFrame(hcat(measurements[:, 1] ./ hour_seconds, measurements), labels)

    close(f)
    return sample_name, analysis_name, date_time, data
end

function get_file_extension(instrument)
    if instrument == "Agilent"
        return "*.csv"
    else
        PTerror("unknownInstrument")
    end
end
