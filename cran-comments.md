## Resubmission

This is a resubmission of `kuzuR`. The version has been bumped to `0.2.4`.

### Summary of Changes and Fixes

- Removed pandas and networkx Python package dependencies from user-facing documentation
- Updated installation instructions to only require the `kuzu` Python package
- Fixed test issues with NA value handling in kuzu_copy_from_df
- Fixed test issues with timezone handling and data type mismatches
- GitHub workflows updated to only install required Python dependencies

### R CMD check results

