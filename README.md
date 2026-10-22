# Wenyin downloads

Wenyin is a local macOS app that redacts sensitive information before a document is shared with AI. This public repository distributes installers only; the application source is private.

## Download

| Your network | Route | Link |
| --- | --- | --- |
| Mainland China | Gitee (fast domestically) | https://gitee.com/songoao25/wenyin-downloads/releases |
| Overseas or with a proxy | GitHub (this repository) | https://github.com/songoao25/wenyin-downloads/releases |

Both routes publish the same build. On a mainland network the GitHub route is often slow or unreachable, so use Gitee; from overseas, GitHub is usually faster. The app can also switch between the two update routes in **Settings → Updates**.

Current build: **2.0.8 (256)**, Apple silicon Macs, macOS 12 or later.

Version retention: this repository keeps every released version. The Gitee mirror keeps only the latest three because of its 1 GB attachment limit per repository.

## Install

Open the DMG, drag Wenyin into Applications, then launch it. The build is not notarized. If macOS blocks it, try to open the app once, then choose **Open Anyway** for Wenyin in System Settings → Privacy & Security (macOS 12: System Preferences → Security & Privacy). Keep system security enabled.

Import DOCX or text-based PDF, review the detected details, then inspect the exported copy. Detection is incomplete, so review every item; scanned documents are not supported. Documents are processed on your Mac only. Only the update check uses the network; documents and usage statistics are never uploaded.

All rights reserved. This is not an open-source repository. Third-party licence notices are included in the application; the same text is linked from the legal page on the website.
