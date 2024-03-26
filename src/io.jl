function read_file(
    file::AbstractString;
    instrument::AbstractString = "Agilent",
    date_time_format::DateFormat = Dates.DateFormat("d/m/Y H:M:S"),
)
    if instrument == "Agilent"
        sample_name, analysis_name, date_time, data =
            read_agilent(file; date_time_format = date_time_format)
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

function load(
    directory_name::AbstractString;
    instrument::AbstractString = "Agilent",
    date_time_constructor::AbstractString = "automatic",
    day_first::Bool = true,
)
    files = glob(get_file_extension(instrument), directory_name)
    analyses = Vector{Sample}(undef, length(files))
    date_times = Vector{DateTime}(undef, length(files))
    date_time_format = date_format_test(
        files[1];
        instrument = instrument,
        date_time_constructor = date_time_constructor,
        day_first = day_first,
    )
    @threads for i in eachindex(files)
        try
            analyses[i] = read_file(
                files[i];
                instrument = instrument,
                date_time_format = date_time_format,
            )
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
    file::AbstractString;
    date_time_format::DateFormat = Dates.DateFormat("d/m/Y H:M:S"),
)
    lines = split(readuntil(file, "Time "), "\n")
    # read header
    analysis_name = split(lines[1], "\\")[end][begin:(end - 2)]
    sample_name = rstrip(analysis_name[begin:(findlast("-", analysis_name)[1] - 1)])
    date_time = rstrip(
        lines[3][(findfirst(":", lines[3])[1] + 2):(findfirst("using", lines[3])[1] - 1)],
    )
    date_time = DateTime(date_time, date_time_format)
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

"""
    automatic_datetime(datetime_string::AbstractString; [day_first::Bool=true])

    Attempt to automatically determine the `date_time_format` given only the string and
    day month order.

    - `day_first` should be either true (default) for dmy order, or false for myd order.

    Will determine if year is first by looking for a string of length 4 before the first
    delimiter. If year is first, will assume ymd order. Will not work with years only 2
    numeric length (e.g. 23/12/21 is ambiguous). In this case you will need to specify the
    `date_time_format` manually.

    Assumes a delimiter in the the date string, and `:` as the delimiter for time string.
"""
function automatic_datetime(datetime_string::AbstractString; day_first::Bool = true)
    if occursin(r"-", datetime_string) == true
        date_delim = '-'
    elseif occursin(r"/", datetime_string) == true
        date_delim = '/'
    end
    if occursin(r"(?i:AM|PM)", datetime_string) == true
        time_format = "H:M:S p"
    else
        time_format = "H:M:S"
    end
    if length(split(datetime_string, r"[-\/ ]")[1]) == 4
        date_format = "Y$(date_delim)m$(date_delim)d"
    elseif day_first === true
        date_format = "d$(date_delim)m$(date_delim)Y"
    elseif day_first === false
        date_format = "m$(date_delim)d$(date_delim)Y"
    end
    return DateFormat(date_format * " " * time_format)
end

function date_format_test(
    file::AbstractString;
    instrument::AbstractString,
    date_time_constructor::AbstractString,
    day_first::Bool = true,
)
    if instrument == "Agilent"
        lines = split(readuntil(file, "Time "), "\n")
        date_time = rstrip(
            lines[3][(findfirst(":", lines[3])[1] + 2):(findfirst("using", lines[3])[1] - 1)],
        )
    else
        PTerror("unknownInstrument")
    end
    if occursin("auto", date_time_constructor) === true
        date_time_format = automatic_datetime(date_time; day_first = day_first)
    else
        date_time_format = Dates.DateFormat(date_time_constructor)
    end
    try
        DateTime(date_time, date_time_format)
    catch err
        throw(
            ArgumentError(
                "Date format is incorrect, if specifying a custom format please see: \n \
                ? Dates.DateFormat or use automatic construction.\n If using automatic \
                construction, specify the correct format instead, \n or file a bug report \
                if it is an unambiguous string.",
            ),
        )
    end
    return date_time_format
end
