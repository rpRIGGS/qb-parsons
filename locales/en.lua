local Translations = {
    error = {
        missing_admission_location = 'Parsons admission locations are not configured.',
        no_active_hold = 'No active Parsons commitment was found.',
        not_authorized = 'Discharge requires authorized medical or judicial clearance.'
    },
    success = {
        discharged = 'You have been discharged from Parsons.'
    },
    info = {
        admitted = 'You have been admitted to Parsons Rehabilitation Center.',
        check_hold = 'Check commitment status',
        check_hold_prompt = '[E] Check commitment status',
        hold_active = 'Your commitment is still active.',
        discharge_pending = 'Your discharge is pending authorization.'
    }
}
Lang = Lang or Locale:new({phrases = Translations, warnOnMissing = true})
