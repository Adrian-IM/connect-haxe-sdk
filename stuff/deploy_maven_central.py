# This file is part of the Ingram Micro CloudBlue Connect SDK.
# Copyright (c) 2019 Ingram Micro. All Rights Reserved.

import os

profiles_url = 'https://oss.sonatype.org/service/local/staging/profiles'
deploy_url = 'https://oss.sonatype.org/service/local/staging/deployByRepositoryId'
mvn_user = os.environ['mvn_user']
mvn_password = os.environ['mvn_password']
mvn_passphrase = os.environ['mvn_passphrase']
group_id = 'com.github.javicerveraingram'


def run(args: list) -> str:
    import subprocess
    return subprocess.run(args, stdout=subprocess.PIPE).stdout.decode('utf-8')


def curl(url: str, method: str, data: str) -> str:
    args = [
        'curl',
        '-s',
        '-u', '{}:{}'.format(mvn_user, mvn_password),
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


def parse_xml(content: str) -> object:
    from xml.etree import ElementTree
    return ElementTree.fromstring(content)


def start() -> str:
    data = """
    <promoteRequest>
        <data>
            <description>
                connect.sdk upload
            </description>
        </data>
    </promoteRequest>
    """
    print('Starting repository...')
    response = curl('/'.join([profiles_url, mvn_profile, 'start']), 'post', data)
    root = parse_xml(response)
    if root.tag == 'promoteResponse':
        return root \
            .find('data') \
            .find('stagedRepositoryId') \
            .text
    else:
        text = root \
            .find('errors') \
            .find('error') \
            .find('msg') \
            .text
        raise Exception(text)


def upload(repository_id, filename: str) -> str:
    strip_filename = filename.split('/')[-1]
    dash_split = strip_filename.split('-')
    artifact_id = dash_split[0]
    version = '.'.join([s for s in dash_split[1].split('.') if s.isdigit()])
    url_comps = [deploy_url, repository_id]
    url_comps.extend(group_id.split('.'))
    url_comps.append(artifact_id)
    url_comps.append(version)
    url_comps.append(strip_filename)
    url = '/'.join(url_comps)
    print('Uploading "{}" to "{}"...'.format(filename, url))
    response = curl(url, '--upload-file', filename)
    return response


def close() -> str:
    print('Closing repository...')


def release() -> str:
    print('Releasing repository...')


def sign(filename: str) -> str:
    print('Signing "' + filename + '"...')
    return run(['gpg', '--batch', '--yes', '--passphrase', mvn_passphrase, '-ab', filename])


def md5(filename: str) -> str:
    import hashlib
    print('Generating MD5 checksum for file "' + filename + '"...')
    md5 = hashlib.md5()
    with open(filename, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            md5.update(chunk)
    digest = md5.hexdigest()
    with open(filename + '.md5', 'w') as f:
        f.write(digest)
    return digest


def sha1(filename: str) -> str:
    import hashlib
    print('Generating SHA1 checksum for file "' + filename + '"...')
    with open(filename, 'rb') as f:
        contents = f.read()
    sha1 = hashlib.sha1(contents)
    digest = sha1.hexdigest()
    with open(filename + '.sha1', 'w') as f:
        f.write(digest)
    return digest


if __name__ == '__main__':
    path = '_build/java'
    files = [
        'connect.sdk-18.0.jar',
        'connect.sdk-18.0.pom',
        'connect.sdk-18.0-sources.jar',
        'connect.sdk-18.0-javadoc.jar'
    ]

    # repository_id = start()
    repository_id = 'comgithubjavicerveraingram-1065'

    for file in files:
        fullname = '/'.join([path, file])
        print(upload(repository_id, fullname))
        print(md5(fullname))
        print(upload(repository_id, fullname + '.md5'))
        print(sha1(fullname))
        print(upload(repository_id, fullname + '.sha1'))
        print(sign(fullname))
        print(upload(repository_id, fullname + '.asc'))
    
    close()

    release()

    print('Done.')
