# LuckyBrain App

LuckyBrain is a web and mobile application for cognitive rehabilitation for people after stroke. It offers a set of exercises to support eye-hand coordination, ear-hand coordination, memory and logical thinking. It features an intuitive interface created in Flutter, a Hive database for storing data and statistics and a comprehensive API for managing user data and progress. The application was tested with patients and medical professionals. The project was developed as an engineering effort and is based on market analysis and user feedback, allowing for further development and improvement.

## Table of contents

* [System requirements](#system-requirements)
* [Initial startup and configuration](#initial-startup-and-configuration)
* [Functionality of the application](#functionality-of-the-application)
* [Navigation and interface](#navigation-and-interface)
* [Troubleshooting](#troubleshooting)
* [Privacy and data management](#privacy-and-data-management)
* [Contact and support](#contact-and-support)
* [Additional comments](#additional-comments)
* [Recommended use](#recommended-use)
* [Documentation](#documentation)
* [How to Contribute to the Project](#how-to-contribute-to-the-project)

## System requirements

* The app requires a device running Android 8.0 or later or iOS 13.0 or later and at least 50 MB of free disk space.
* To ensure optimal display, the device should have a screen resolution of 720x1280 pixels or higher.
* An internet connection is required for initial setup and data synchronization.

## Initial startup and configuration

The setup process includes selecting the preferred language, choosing between light and dark display modes, and creating a user profile.

## Functionality of the application

The app focuses its themes around four categories of training tasks cognitive: memory, logic, eye-hand coordination and ear-hand coordination. In each category there are three carefully selected tasks with several levels of difficulty. Each task has a timer and immediate audio feedback to the
individual examples for correct or incorrect answers. The tasks become progressively more difficult to make teaching more effective. The progress tracking module offers statistics in the form of graphs and an interactive calendar. Users can monitor training dates, duration and results.

## Navigation and interface

The application has a friendly and easy-to-understand interface. It is not too complicated, and its elements are laid out in an optimal way. The colors used are contrasting, which means that even people with visual impairments, let alone aging viewers, can easily use the application.Navigation shouldn't be too difficult either major difficulties. In terms of usability, the app presents a high level.

## Troubleshooting

* When technical problems arise with the device, first check, whether it meets the system requirements and whether there is sufficient disk space.
* If you can't save settings, the problem is most often memory-related. You should determine whether there is sufficient memory to allocate and whether the application you are you are working with has been granted the required permissions.

## Privacy and data management

Maintaining user privacy is a top priority. All data is stored with great care using local database technology, with possible data synchronization in the cloud.

## Contact and support

Users can contact the developer at the specified email address for questions, concerns, suggestions and, importantly, when they need technical support.

## Additional comments

Users are encouraged to provide feedback in order to improve the cognitive training. LuckyBrain was created with rehabilitation and improvement of cognitive function in mind and is not just a “test” application. It is part of a health-educational approach to so-called “HealthTech,” based largely on available information about the patient's cognitive state leading to tailored solutions.

## Recommended use

To achieve the best results, the application should be used in a systematically and using a variety of tasks in the cognitive area. Daily exercises in a 3-2-1 system. three tasks from different cognitive areas, two at night, before sleep and one in the morning, just after waking up.

## Documentation

### Requirements specification

#### Objectives of the system

* To provide rehabilitation exercises for people after stroke.
* To enable progress tracking and performance monitoring.
* To support both independent and therapist-led rehabilitation.
* Provide accessibility on online and mobile platforms.

#### System components

* Visual layer (Flutter)
* Database (Hive)
* Exercise engine
* Analysis module
* Management system

### Functional requirements

* User registration
* Cognitive exercises
* Progress tracking
* Adjustment of difficulty
* Sound system

### Use case model

Actors:

* Patient - the main user of the system
* Provider - therapist or caregiver
* Administrator - managing the system
* Exercise engine - generation and operation of exercises

### System architecture

Layers of architecture:

* Presentation - user interface (Flutter)
* Business - application logic (exercise engine, analytics)
* Data - data storage and management (Hive database)

Software components:

* Core - Flutter, Hive, exercise engine, analytics module
* Services - authentication, progress tracking, exercise management, analytics

Process flow:

* Authentication
* Exercise selection
* Exercise execution
* Recording progress

## How to Contribute to the Project

I encourage reporting bugs, proposing features, and creating pull requests.