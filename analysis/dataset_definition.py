from argparse import ArgumentParser
import datetime
from ehrql import create_dataset, case, when

from ehrql.tables.tpp import (
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

# Get start and end date from project.yaml
parser = ArgumentParser()
parser.add_argument("--start-date", type=datetime.date.fromisoformat)
parser.add_argument("--end-date", type=datetime.date.fromisoformat)
args = parser.parse_args()
start_date = args.start_date
end_date = args.end_date

# Instantiate dataset
dataset = create_dataset()
dataset.configure_dummy_data(population_size=5000)

# Extract clinical events that fall between our start and end date
# for further use in variable definitions below
selected_events = clinical_events.where(
    clinical_events.date.is_on_or_between(start_date, end_date)
)

# Virtual consultations identified through clinical codes
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

dataset.last_virtual_consultation_code = (
    selected_events.where(clinical_events.snomedct_code.is_in(virtual_consultation))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

# f2f (face to face) consultations identified through clinical codes
dataset.has_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(f2f_consultation)
).exists_for_patient()

# Count number of f2f that a patient had
dataset.count_f2f_consultation = selected_events.where(
    clinical_events.snomedct_code.is_in(f2f_consultation)
).count_for_patient()

dataset.last_f2f_consultation_code = (
    selected_events.where(clinical_events.snomedct_code.is_in(f2f_consultation))
    .sort_by(clinical_events.date)
    .last_for_patient()
    .snomedct_code
)

# Appointments identified through the appointments table
# Get all appointments with status "Finished"
appointments_seen = appointments.where(
    appointments.status.is_in(
        [
            "Arrived",
            "In Progress",
            "Finished",
            "Visit",
            "Waiting",
            "Patient Walked Out",
        ]
    )
).where(appointments.seen_date.is_on_or_between(start_date, end_date))

dataset.last_appointment_status = (
    appointments_seen.sort_by(appointments_seen.seen_date).last_for_patient().status
)


# Count number of total seen appointments in the time period
dataset.count_appointment = appointments_seen.count_for_patient()
# Specify if a patient had (True/False) a finished appointment in the time period
dataset.has_appointment = appointments_seen.exists_for_patient()

# Demographic variables and other patient characteristics
# Define variable that checks if a patients is registered at the start date
has_registration = practice_registrations.for_patient_on(
    start_date
).exists_for_patient()

dataset.age = patients.age_on(start_date)
dataset.age_greater_equal_65 = dataset.age >= 65

# Define patient sex and date of death
dataset.sex = patients.sex
dataset.dod = patients.date_of_death

# Define patient address: MSOA, rural-urban and IMD rank, using latest data for each patient
latest_address_per_patient = addresses.sort_by(addresses.start_date).last_for_patient()
imd_rounded = latest_address_per_patient.imd_rounded
dataset.imd_quintile = case(
    when((imd_rounded >= 0) & (imd_rounded < int(32844 * 1 / 5))).then("1"),
    when(imd_rounded < int(32844 * 2 / 5)).then("2"),
    when(imd_rounded < int(32844 * 3 / 5)).then("3"),
    when(imd_rounded < int(32844 * 4 / 5)).then("4"),
    when(imd_rounded < int(32844 * 5 / 5)).then("5"),
    otherwise="Missing",
)

# Define patient ethnicity
latest_ethnicity_code = (
    clinical_events.where(clinical_events.snomedct_code.is_in(ethnicity_codelist))
    .where(clinical_events.date.is_on_or_before(end_date))
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
    otherwise="missing",
)

# Define population to be registered and above 18 years old
dataset.define_population(has_registration & (dataset.age >= 18))
