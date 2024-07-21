function PTerror(key)
    errormessages = Dict(
        "ndriftzero" => "ndrift must be >0",
        "notStandard" => "The sample has not been marked as a standard",
        "unknownRefMat" => "Unknown reference material.",
        "unknownMethod" => "Unknown method.",
        "unknownInstrument" => "Unsupported instrument."
    )
    throw(error(errormessages[key]))
end
