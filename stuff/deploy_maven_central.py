# This file is part of the Ingram Micro CloudBlue Connect SDK.
# Copyright (c) 2019 Ingram Micro. All Rights Reserved.

# Developed following the instructions here:
# https://support.sonatype.com/hc/en-us/articles/213465868?_ga=2.230043868.1594253912.1579542012-1885361292.1578410493

import os
import time
from xml.etree import ElementTree

DEPLOY_URL = 'https://oss.sonatype.org/service/local/staging/deployByRepositoryId'
PROFILES_URL = 'https://oss.sonatype.org/service/local/staging/profiles'
PROFILE_REPOSITORIES_URL = 'https://oss.sonatype.org/service/local/staging/profile_repositories'
MVN_USER = os.environ['mvn_user']
MVN_PASSWORD = os.environ['mvn_password']
MVN_PASSPHRASE = os.environ['mvn_passphrase']
PATH = '_build/java'
FILES = [
    'connect.sdk-18.0.1.jar',
    'connect.sdk-18.0.1.pom',
    'connect.sdk-18.0.1-sources.jar',
    'connect.sdk-18.0.1-javadoc.jar'
]
GROUP_ID = ElementTree \
    .parse('/'.join([PATH, FILES[1]])) \
    .getroot() \
    .find('{http://maven.apache.org/POM/4.0.0}groupId') \
    .text


def run(args: list) -> str:
    import subprocess
    return subprocess.run(args, stdout=subprocess.PIPE).stdout.decode('utf-8')


def curl(url: str, method: str, data: str = None) -> str:
    args = [
        'curl',
        '-s',
        '-u', '{}:{}'.format(MVN_USER, MVN_PASSWORD),
    ]
    if method.lower() == '--upload-file':
        args.extend(['-H', 'Content-Type:application/x-jar'])
        args.extend(['--upload-file', data])
    else:
        args.extend(['-X', method.upper()])
        if data:
            args.extend(['-H', 'Content-Type:application/xml'])
            args.extend(['-d', data])
    args.append(url)
    return run(args)


def xml_error(elem: ElementTree) -> str:
    if elem.tag == 'nexus-error':
        return elem \
            .find('errors') \
            .find('error') \
            .find('msg') \
            .text
    else:
        return None


def start(profile_id: str) -> str:
    print('*** Starting repository...', flush=True)
    data = """
    <promoteRequest>
        <data>
            <description>connect.sdk upload</description>
        </data>
    </promoteRequest>
    """
    response = curl('/'.join([PROFILES_URL, profile_id, 'start']), 'post', data)
    root = ElementTree.fromstring(response)
    if root.tag == 'promoteResponse':
        return root \
            .find('data') \
            .find('stagedRepositoryId') \
            .text
    else:
        raise Exception(xml_error(root))


def upload(repository_id: str, filename: str) -> str:
    strip_filename = filename.split('/')[-1]
    dash_split = strip_filename.split('-')
    artifact_id = dash_split[0]
    version = '.'.join([s for s in dash_split[1].split('.') if s.isdigit()])
    url_comps = [DEPLOY_URL, repository_id]
    url_comps.extend(GROUP_ID.split('.'))
    url_comps.append(artifact_id)
    url_comps.append(version)
    url_comps.append(strip_filename)
    url = '/'.join(url_comps)
    print('*** Uploading "{}" to "{}"...'.format(filename, url), flush=True)
    response = curl(url, '--upload-file', filename)
    return response


def finish(profile_id: str, repository_id: str) -> str:
    print('*** Closing repository...', flush=True)
    data = """
    <promoteRequest>
        <data>
            <stagedRepositoryId>{}</stagedRepositoryId>
            <description>connect.sdk upload</description>
        </data>
    </promoteRequest>
    """.format(repository_id)
    response = curl('/'.join([PROFILES_URL, profile_id, 'finish']), 'post', data)
    return response


def repository_status(profile_id: str, repository_id: str) -> str:
    print('*** Getting staging repositories...', flush=True)
    response = curl('/'.join([PROFILE_REPOSITORIES_URL, profile_id]), 'get')
    root = ElementTree.fromstring(response)
    if root.tag == 'stagingRepositories':
        data = root.find('data')
        repos = [repo for repo in data if repo.find('repositoryId').text == repository_id]
        return repos[0].find('type').text
    else:
        raise Exception(xml_error(root))


def release() -> str:
    print('*** Releasing repository...', flush=True)
    data = """
    <promoteRequest>
        <data>
            <stagedRepositoryId>{}</stagedRepositoryId>
            <description>connect.sdk upload</description>
        </data>
    </promoteRequest>
    """.format(repository_id)
    response = curl('/'.join([PROFILES_URL, profile_id, 'release']), 'post', data)
    return response


def sign(filename: str) -> str:
    print('*** Signing "' + filename + '"...', flush=True)
    return run(['gpg', '--batch', '--yes', '--passphrase', MVN_PASSPHRASE, '-ab', filename])


def md5(filename: str) -> str:
    print('*** Generating MD5 checksum for file "' + filename + '"...', flush=True)
    import hashlib
    md5 = hashlib.md5()
    with open(filename, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            md5.update(chunk)
    digest = md5.hexdigest()
    with open(filename + '.md5', 'w') as f:
        f.write(digest)
    return digest


def sha1(filename: str) -> str:
    print('*** Generating SHA1 checksum for file "' + filename + '"...', flush=True)
    import hashlib
    with open(filename, 'rb') as f:
        contents = f.read()
    sha1 = hashlib.sha1(contents)
    digest = sha1.hexdigest()
    with open(filename + '.sha1', 'w') as f:
        f.write(digest)
    return digest


def get_profile_id() -> str:
    print('*** Getting profiles...', flush=True)
    response = curl(PROFILES_URL, 'get')
    root = ElementTree.fromstring(response)
    if root.tag == 'stagingProfiles':
        data = root.find('data')
        profiles = [profile for profile in data if profile.find('name').text == GROUP_ID]
        profile_id = profiles[0].find('id').text
        print('*** Found profile id ' + profile_id, flush=True)
        return profile_id
    else:
        raise Exception(xml_error(root))


if __name__ == '__main__':
    profile_id = get_profile_id()
    repository_id = start(profile_id)

    # Upload all files, signatures and digests
    for file in FILES:
        fullname = '/'.join([PATH, file])
        print(upload(repository_id, fullname), flush=True)
        sign(fullname)
        print(upload(repository_id, fullname + '.asc'), flush=True)
        md5(fullname)
        print(upload(repository_id, fullname + '.md5'), flush=True)
        sha1(fullname)
        print(upload(repository_id, fullname + '.sha1'), flush=True)
    
    print(finish(profile_id, repository_id), flush=True)

    # Wait until the repository gets successfully closed
    print('Waiting until the repository is closed...', flush=True)
    num_attempts = 0
    status = repository_status(profile_id, repository_id)
    while num_attempts < 10 and status != 'closed':
        print('*** Got repository status ' + status, flush=True)
        num_attempts += 1
        print('*** Sleeping for 30 seconds...', flush=True)
        time.sleep(30)
        status = repository_status(profile_id, repository_id)

    # print(release(), flush=True)

    print('*** Done.', flush=True)
