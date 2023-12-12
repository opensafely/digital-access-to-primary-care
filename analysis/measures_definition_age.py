from ehrql import INTERVAL, create_measures, case, when, months, weeks

from ehrql.tables.beta.tpp import (
    clinical_events,
    patients,
    practice_registrations,
    addresses,
    appointments,
)

from codelists import (
    f2f_consultation,
    virtual_consultation,
    ethnicity_codelist,
)

# Instantiate dataset
measures = create_measures()

# Extract clinical events that fall between our start and end date
# for further use in variable definitions below
selected_events = clinical_events.where(
    clinical_events.date.is_on_or_between(INTERVAL.start_date, INTERVAL.end_date)
)

# Virtual consultations identified through clinical codes
# Check if a patient has a clinical code in the time period defined
# above (selected_events) that are in the virtual_consultation codelist
has_virtual_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(virtual_consultation)
).exists_for_patient()

# Count number of virtual_consultation that a patient had
# in the time period defined above (selected_events)
count_virtual_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(virtual_consultation)
).count_for_patient()

last_virtual_consultation_code = (
    selected_events.where(clinical_events.snomedct_code.is_in(virtual_consultation))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

# f2f (face to face) consultations identified through clinical codes
has_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(f2f_consultation)
).exists_for_patient()

# Count number of f2f that a patient had
count_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(virtual_consultation)
).count_for_patient()

last_f2f_consultation_code = (
    selected_events.where(clinical_events.snomedct_code.is_in(f2f_consultation))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

# Appointments identified through the appointments table
# Get all appointments with a seen date
appointments_with_seen_date = appointments.where(
    appointments.seen_date <= INTERVAL.end_date,
).where(appointments.status.is_in(["Finished"]))

# Count number of appointments with a seen date in the time period
count_appointment = appointments_with_seen_date.count_for_patient()
# Specify if a patient had (True/False) an appointment with a seen date
has_appointment = appointments_with_seen_date.exists_for_patient()

# Demographic variables and other patient characteristics
# Define variable that checks if a patients is registered at the start date
has_registration = practice_registrations.for_patient_on(
    INTERVAL.start_date
).exists_for_patient()

age = patients.age_on(INTERVAL.start_date)
age_greater_equal_65 = age >= 65

# Define patient sex and date of death
sex = patients.sex
dod = patients.date_of_death

# Define patient address: MSOA, rural-urban and IMD rank, using latest data for each patient
latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
imd_rounded = latest_address_per_patient.imd_rounded
imd_quintile = case(
    when((imd_rounded >= 0) & (imd_rounded < int(32844 * 1 / 5))).then("1"),
    when(imd_rounded < int(32844 * 2 / 5)).then("2"),
    when(imd_rounded < int(32844 * 3 / 5)).then("3"),
    when(imd_rounded < int(32844 * 4 / 5)).then("4"),
    when(imd_rounded < int(32844 * 5 / 5)).then("5"),
    default="Missing",
)

# Define patient ethnicity
latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_codelist))
    .where(clinical_events.date.is_on_or_before(INTERVAL.end_date))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

latest_ethnicity = latest_ethnicity_code.to_category(ethnicity_codelist)

# Convert ethnicity group numbers into strings
ethnicity = case(
    when(latest_ethnicity == "1").then("White"),
    when(latest_ethnicity == "2").then("Mixed"),
    when(latest_ethnicity == "3").then("Asian or Asian British"),
    when(latest_ethnicity == "4").then("Black or Black British"),
    when(latest_ethnicity == "5").then("Chinese or Other Ethnic Groups"),
    default="missing",
)

# Define population denominator
denominator = has_registration & (age > 18) & has_appointment

# # Define monthly measure
# measures.define_measure(
#     name="virtual_consultations_pre_monthly",
#     numerator=has_virtual_consultation,
#     denominator=denominator,
#     group_by={"age_greater_equal_65": age_greater_equal_65},
#     intervals=months(6).starting_on("2019-04-01"),
# )

# measures.define_measure(
#     name="appointments_pre_monthly",
#     numerator=has_appointment,
#     denominator=denominator,
#     group_by={"age_greater_equal_65": age_greater_equal_65},
#     intervals=months(6).starting_on("2019-04-01"),
# )

# measures.define_measure(
#     name="virtual_consultations_during_monthly",
#     numerator=has_virtual_consultation,
#     denominator=denominator,
#     group_by={"age_greater_equal_65": age_greater_equal_65},
#     intervals=months(6).starting_on("2020-04-01"),
# )

# measures.define_measure(
#     name="appointments_during_monthly",
#     numerator=has_appointment,
#     denominator=denominator,
#     group_by={"age_greater_equal_65": age_greater_equal_65},
#     intervals=months(6).starting_on("2020-04-01"),
# )

# Define weekly measure
measures.define_measure(
    name="virtual_consultations_pre_weekly",
    numerator=has_virtual_consultation,
    denominator=denominator,
    group_by={"age_greater_equal_65": age_greater_equal_65},
    intervals=weeks(10).starting_on("2019-04-01"),
)

measures.define_measure(
    name="virtual_consultations_during_weekly_2020",
    numerator=has_virtual_consultation,
    denominator=denominator,
    group_by={"age_greater_equal_65": age_greater_equal_65},
    intervals=weeks(10).starting_on("2020-04-01"),
)

measures.define_measure(
    name="virtual_consultations_during_weekly_2021",
    numerator=has_virtual_consultation,
    denominator=denominator,
    group_by={"age_greater_equal_65": age_greater_equal_65},
    intervals=weeks(10).starting_on("2021-04-01"),
)

