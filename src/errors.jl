function PTerror(key)
    errormessages = Dict(
        "notStandard" => "The sample has not been marked as a standard",
        "missingAttribute" => "Missing attribute",
        "missingWindows" => "Missing selection windows. Run setBlank!(...) or setSignal!(...) first.",
        "missingBlank" => "No blank model fitted. Run fitBlanks!(...) first.",
        "missingStandard" => "The data haven't be calibrated. Run fitStandards!(...) first.",
        "undefinedMethod" => "Undefined method.",
        "unknownRefMat" => "Unknown reference material.",
        "unknownMethod" => "Unknown method.",
        "isochanmismatch" => "The number of channels does not equal number of isotopes.",
        "unknownInstrument" => "Unsupported instrument.",
        "missingNumDen" => "You must provide either a numerator or denominator, or both."
    )
    throw(error(errormessages[key]))
end
