# DRC Documentation

Explains how to use the runset.

## Folder Structure

```text
📁 drc
 ┣ 📁testing                        Testing environment directory for GF180MCU DRC.
 ┣ 📁rule_decks                     All DRC rule decks used in GF180MCU.
 ┣ 📜helper.rb                      Helper functions used in rule_deck files
 ┣ 📜README.md                      This file to document the DRC run for GF180MCU.
 ┣ 📜generic_layers.rb              Extracts layers of GF180MCU.
 ┣ 📜connectivity.rb                Builds connectivity beetween layers of GF180MCU
 ┣ 📜options.rb                     Parse options for gf180mcu.drc script
 ┣ 📜rule_framework.rb              PDK agnostic framework for rule parsing, execution and analysis
 ┗ 📜gf180mcu.drc                   Main script used for GF180MCU DRC.
 ```

## **Prerequisites**
You need the following set of tools installed to be able to run GF180MCU DRC:
- KLayout 0.28.4+

## **Usage**

The `gf180mcu.drc` script takes your input gds file to run DRC rule decks of GF180 technology on it with switches to select subsets of all checks.

Check its usage via
```bash
    klayout -b -r gf180mcu.drc -rd help=true
```

If using parallel runners > 1, be mindful that issues could arise with klayout versions prior than 0.30.9

The result is a database file containing run results all violations.
You could view it on your file using: `klayout <input_gds_file> -m <resut_db_file> `, or you could view it on your gds file via marker browser option in tools menu using klayout GUI as shown below.

![image](https://user-images.githubusercontent.com/91015308/219004873-be7c1e81-7085-4e82-8cd4-8303bc021e13.png)


