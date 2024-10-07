---
title: 17
platform: iOS
---

# iOS/iPadOS 17 <Badge type="tip" text="Current Version (N-1)" />

::: tip STABLE RELEASE WITH SOME SECURITY UPDATES 
This version of iOS and iPadOS may not include the newest security features or address all known security issues due to dependencies on architectural and system changes introduced in the latest version available as of now. To maintain your device's security, stability, and compatibility, Apple recommends using the latest iOS and iPadOS that is compatible with your device.
:::

<script setup>
import LatestFeatures from './components/LatestFeatures.vue';
import SecurityInfo from './components/SecurityInfo.vue';

const frontmatter = {
  title: 'iOS 17',
  platform: 'iOS',
  stage: 'release',
};
</script>

## Latest Release Info
<LatestFeatures :title="frontmatter.title" :platform="frontmatter.platform" :stage="frontmatter.stage" />

## Essential Apple Resources
<LinksComponent :title="frontmatter.title" :platform="frontmatter.platform" :stage="frontmatter.stage" />

## Security Information
<SecurityInfo :title="frontmatter.title" :platform="frontmatter.platform" :stage="frontmatter.stage" />
