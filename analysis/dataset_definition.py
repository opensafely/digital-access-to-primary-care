from ehrql import Dataset, case, when

from ehrql.tables.beta.tpp import (
    clinical_events,
    patients,
    practice_registrations,
    addresses,
)

from codelists import (
    f2f_consultation,
    virtual_consultation,
    ethnicity_codelist,
)

# Define start and end date of study period because we are using these dates
# at various places further down in the dataset definition
start_date = "2020-04-01"
end_date = "2021-03-31"

# Instantiate dataset
dataset = Dataset()

# Extract clinical events that fall between our start and end date
# for further use in variable definitions below
selected_events = clinical_events.where(
    clinical_events.date.is_on_or_between(start_date, end_date)
)

# Define variable that checks if a patients is registered at the start date
has_registration = practice_registrations.for_patient_on(
    start_date
).exists_for_patient()

dataset.age = patients.age_on(start_date)
dataset.age_greater_equal_65 = dataset.age >= 65

# Check if a patient has a clinical code in the time period defined
# above (selected_events) that are in the f2f_consultation codelist
dataset.has_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(f2f_consultation)
).exists_for_patient()

# Count number of f2f_consultation that a patient had
# in the time period defined above (selected_events)
dataset.count_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(f2f_consultation)
).count_for_patient()

# Check if a patient has a clinical code in the time period defined
# above (selected_events) that are in the virtual_consultation codelist
dataset.has_virtual_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(virtual_consultation)
).exists_for_patient()

# Count number of virtual_consultation that a patient had
# in the time period defined above (selected_events)
dataset.count_virtual_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(virtual_consultation)
).count_for_patient()

# Define population, currently I set the conditions that patients need to be
# registered and above 18 to be included
dataset.define_population(has_registration & (dataset.age > 18))

# Define patient address: MSOA, rural-urban and IMD rank, using latest data for each patient
latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
imd_rounded = latest_address_per_patient.imd_rounded
dataset.imd_quintile = case(
    when((imd_rounded >= 0) & (imd_rounded < int(32844 * 1 / 5))).then("1"),
    when(imd_rounded < int(32844 * 2 / 5)).then("2"),
    when(imd_rounded < int(32844 * 3 / 5)).then("3"),
    when(imd_rounded < int(32844 * 4 / 5)).then("4"),
    when(imd_rounded < int(32844 * 5 / 5)).then("5"),
    default="Missing",
)

# Define patient sex and date of death
dataset.sex = patients.sex
dataset.dod = patients.date_of_death

# Define patient ethnicity
latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_codelist))
    .where(clinical_events.date.is_on_or_before("2023-01-01"))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

latest_ethnicity = latest_ethnicity_code.to_category(ethnicity_codelist)

# Convert ethnicity group numbers into strings
dataset.ethnicity = case(
    when(latest_ethnicity == "1").then("White"),
    when(latest_ethnicity == "2").then("Mixed"),
    when(latest_ethnicity == "3").then("Asian or Asian British"),
    when(latest_ethnicity == "4").then("Black or Black British"),
    when(latest_ethnicity == "5").then("Chinese or Other Ethnic Groups"),
    default="missing",
)
