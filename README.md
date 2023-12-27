# TrueAnomaly Telemetry Package Processing

![UML Diagram](docs/telemetry.svg)

The **Telemetry Supervisor** is the parent supervisor of all the telemetry-processing components.

The **File System Watcher** monitors the `files/ingest` directory for new telemetry packages. When one appears, it notifies the **Dynamic Parsers Supervisor** so that file processing components can be started up.

The **File Parser** component is created on a per-file basis and supervises the three components needed for processing the given telemetry file.

The **File Reader** component reads the file header to determine the satellite type and then reads the rest of the file into memory so the data can be distributed to the **Data Normalizer** worker(s).

The **Data Normalizer** component reads the raw data from the file and, based on the satellite type, normalizes the data, including any satellite-type-specific details that need to be stored.

The **Data Persister** component enqueues normalized telemetry data to be persisted to the database. Its function is to validate the data and space out inserts so as not to degrade database performance.

## System design rationale

I designed the system the way I did in order that the various stages of processing the telemetry data file could potentially be scaled independently, but also to demonstrate my knowledge of Supervisors, GenServers, inter-process messaging, etc. Depending on the size of the telemetry files, however, this approach may be overkill.

A simpler approach could be to make use of Elixir's excellent concurrency capabilities to stream the file line-by-line and spin up asynchronous processes that would handle the normalization and persistence of the data.

## Notes

* The Data Normalizer and Data Persister components are intended to be pools of workers that could scale as necessary for extremely large telemetry packages.

* I intended to persist the records using batch inserts, but an unresolved bug in the `polymorphic_embed` library required that I issue individual SQL commands instead.

* When a file's telemetry data has finished being persisted, the components that were created for it are intended to be terminated, but that logic has not been built yet.

* There is some logging that happens if telemetry data fails validation, but a more robust system using Elixir's Telemetry Hex library (coincidentally and confusingly named the same), should be used instead to enable fine-tuning of system events.

* A `Registry` could have been used to help components find one another, rather than hand-crafting process names based on the component and file ID as I did.

* I hope it is understood that I would have added many tests were this a real system.

## Files of interest

There's not a lot of code, but the most interesting files are probably:

* `lib/true_anomaly/telemetry/telemetry.ex`
* `lib/true_anomaly/instruments/*.ex`
* `lib/true_anomaly/data_normalizer.ex`
* `lib/true_anomaly/data_persister.ex`

## Running the system

If you wish to see the system run, it is functional and nothing beyond the standard Elixir/Phoenix setup steps is required.

Once the app is running, simply copy one (or both!) of the files from the `/files` directory into the `/files/ingest` directory. The workers will see them and begin processing.