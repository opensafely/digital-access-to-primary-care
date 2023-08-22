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
start_date = "2019-04-01"
end_date = "2020-03-31"

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

dataset.patient_age = patients.age_on(start_date)
dataset.patient_age_ge65 = dataset.patient_age >= 65

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

dataset.has_f2f_and_virtual_consultation = dataset.has_virtual_consultation & dataset.has_f2f_consultation
dataset.has_f2f_or_virtual_consultation = dataset.has_virtual_consultation | dataset.has_f2f_consultation

# Define the date of clinical event
f_clincal_date = clinical_events.where(
        clinical_events.snomedct_code.is_in(f2f_consultation)
).sort_by(
    clinical_events.date
).first_for_patient().date.month

dataset.f2f_clinical_date = case(
    when(f_clincal_date == 1).then("January"),
    when(f_clincal_date == 2).then("February"),
    when(f_clincal_date == 3).then("March"),
    when(f_clincal_date == 4).then("April"),
    when(f_clincal_date == 5).then("May"),
    when(f_clincal_date == 6).then("June"),
    when(f_clincal_date == 7).then("July"),
    when(f_clincal_date == 8).then("August"),
    when(f_clincal_date == 9).then("September"),
    when(f_clincal_date == 10).then("October"),
    when(f_clincal_date == 11).then("November"),
    when(f_clincal_date == 12).then("December"),
    default="missing",
)

v_clincal_date = clinical_events.where(
        clinical_events.snomedct_code.is_in(virtual_consultation)
).sort_by(
    clinical_events.date
).first_for_patient().date.month

dataset.virtual_clinical_date = case(
    when(v_clincal_date == 1).then("January"),
    when(v_clincal_date == 2).then("February"),
    when(v_clincal_date == 3).then("March"),
    when(v_clincal_date == 4).then("April"),
    when(v_clincal_date == 5).then("May"),
    when(v_clincal_date == 6).then("June"),
    when(v_clincal_date == 7).then("July"),
    when(v_clincal_date == 8).then("August"),
    when(v_clincal_date == 9).then("September"),
    when(v_clincal_date == 10).then("October"),
    when(v_clincal_date == 11).then("November"),
    when(v_clincal_date == 12).then("December"),
    default="missing",
)

# Define population, currently I set the conditions that patients need to be
# registered and above 18 to be included
dataset.define_population(has_registration & (dataset.patient_age > 18))

# Define patient address: MSOA, rural-urban and IMD rank, using latest data for each patient
latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
dataset.patient_msoa = latest_address_per_patient.msoa_code
dataset.patient_rural_urban = latest_address_per_patient.rural_urban_classification
dataset.patient_imd_rounded = latest_address_per_patient.imd_rounded

# Define patient sex and date of death
dataset.patient_sex = patients.sex
dataset.patient_dod = patients.date_of_death

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
