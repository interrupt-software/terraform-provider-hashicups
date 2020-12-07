### HashiCups
The motivation for this exercise is to present an API service and reference the data with a private Terraform provider. In this scenario, the API service is temporarily hosted at [http://ec2-52-55-246-151.compute-1.amazonaws.com:19090/coffees](http://ec2-52-55-246-151.compute-1.amazonaws.com:19090/coffees). The end result is the ability to use a custom-developed, Terraform provider to access the HashiCups API service, and use the metadata to provision additional services.

The HashiCups example is based on the [Learn Guide](https://learn.hashicorp.com/tutorials/terraform/provider-use?in=terraform/providers). It is assumed that we have a working provider.

---
### Registry Provider
The structure for the private Registry Provider is as follows:

```
mirror
├── .well-known
│   └── terraform.json
└── v1
    ├── modules
    └── providers
        └── seng
            └── hashicups
                ├── 0.2.0
                │   └── download
                │       ├── darwin
                │       │   └── amd64
                │       └── linux
                │           └── amd64
                └── versions
```
What is relevant here is that [terraform.json](./mirror/.well-known/terraform.json), [versions](./mirror/v1/providers/seng/hashicups/versions), [darwin/amd64](./mirror/v1/providers/seng/hashicups/0.2.0/download/darwin/amd64) and [linux/amd64](./mirror/v1/providers/seng/hashicups/0.2.0/download/linux/amd64) are all JSON-formatted files that provide metadata to the provider.

### Service Discovery

Upon instantiation, the provider registry protocol will query the endpoint for any declared services. For this example we do not need to declare modules but it is included to highlight the purpose of the service discovery use. There is a detailed section with ample detail in the [Provider Registry Protocol](https://www.terraform.io/docs/internals/provider-registry-protocol.html#service-discovery) documentation.

##### .well-known/terraform.json

```
{
  "modules.v1": "/v1/modules/",
  "providers.v1": "/v1/providers/"
}
```

### List Available Versions

The protocol then looks for available versions of the reference provider. In our example, the provider is explictly looking for `seng/hashicups` on the URL endpoint. Thus we are declaring what is available so the protocol is able to introspect the request. If we were to request the provider for a `linux/bsd` platform, or something outside of the `0.2.0` version, then the request should fail. This is illustrated in the documentation under [List Available Sections](https://www.terraform.io/docs/internals/provider-registry-protocol.html#provider-versions).

##### v1/providers/seng/hashicups/versions

```
{
  "id": "seng/hashicups",
  "versions": [
    {
      "version": "0.2.0",
      "protocols": [ "5.0" ],
      "platforms": [
        { "os": "darwin", "arch": "amd64" },
        { "os": "linux", "arch": "amd64" }
      ]
    }
  ],
  "warnings": null
}
```

### Provider Package

Once the protocol determines that an appropriate package is potentially available, it will download the associated metadata about the distribution package. In our example this is true for [darwin/amd64](./mirror/v1/providers/seng/hashicups/0.2.0/download/darwin/amd64) and [linux/amd64](./mirror/v1/providers/seng/hashicups/0.2.0/download/linux/amd64) packages, and there need to be corresponding packages for all supported platform versions in the provider. This part is somewhat documented starting with the [Find a Provider Package section] (https://www.terraform.io/docs/internals/provider-registry-protocol.html#find-a-provider-package).

##### v1/providers/seng/hashicups/0.2.0/download/darwin/amd64

```
{
  "protocols": [
    "5.0"
  ],
  "os": "darwin",
  "arch": "amd64",
  "filename": "terraform-provider-hashicups_0.2.0_darwin_amd64.zip",
  "download_url": "/interrupt-software/seng/hashicups/0.2.0/darwin_amd64/terraform-provider-hashicups_0.2.0_darwin_amd64.zip",
  "shasums_url": "/interrupt-software/seng/hashicups/0.2.0/darwin_amd64/terraform-provider-hashicups_0.2.0_SHA256SUMS",
  "shasums_signature_url": "/interrupt-software/seng/hashicups/0.2.0/darwin_amd64/terraform-provider-hashicups_0.2.0_SHA256SUMS.sig",
  "shasum": "fc7355d19ba718760f780213ea2fb4310882180423e4f027ed8bbf2e2380d851",
  "signing_keys": {
    "gpg_public_keys": [
      {
        "key_id": "B271********D72C",
        "ascii_armor": "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\nmQINBF/NjuoBEACl1fjbuJauNTNckjBeYoKx1BNbJ4mzlSU4pPXsJ5mSy4CoWVAP\nsjcNFHW0Cf/Hu3xXJfvENGuHUD2txycYVUSKL5DibuiRk5LmK4UdDIFvwtH8svb7\nE18+KbIjJuAcs+Dp3mYvZMoNCZBqTDHjuMyDKJbWMKjNUWVsLkpufO/4WbFh5UOo\nnh0Zo+FfeVeDrAku2VOD52JtsH1gR615zxOa2V5jR1O/uXGzUuo8048lxHvIOs17\nsKpnYxcjZaPuVtk7l4MKDlb8be53HkcNnXh8bedApJ0UMAbYFDrUuEiscpNZpjBv\njS3qlZbXrRuDnktQ68DbFpMy98v0eMSwyWsUFi+2+ZnlzfNbIjz3Kvdc5kr+bvLf\n5aUMZB/
        ****  Big missing chunk ****
        k55Che0s1t2HIZ6sOAApbsIy9fxuii6\ny8DfFBCWNORkYExP9IhWBxBNw00tBB7/ZVaeec6ibXk5dGTaszMZ0udbXBW4T8h1\nunab5HHzElcU0msu7ugXgB9GnoNxnCMVM3D6RZlZ3+fdx7+RM4RdySXXXmL1F4E/\nkPF0WzXnlwGHCZOIfbwahsMb/Ip/c10+FK2SkzaNpRtHyvFxGxkn3PH4BHc33lO/\nWZwI0zTgMNkd2iofUqDMU49s9oYgDWIs05DV+PiK1omCpO6YqltgIyjUVYlG06Xk\nxWbqPdXNNkr97QgPfHiwKlE8cQfDxyWsQxgWZkdUSgQcZ2A2iOMP9A54PpeSsbjX\nErLnsw5eXqL69yTXK/MS+4nwFupxI4uv6Lna6RJOFNagfNtUUGLTkTn69SAr1wM=\n=k5Gt\n-----END PGP PUBLIC KEY BLOCK-----",
        "trust_signature": "",
        "source": "",
        "source_url": null
      }
    ]
  }
}
```

For the request to function properly, the protocol requires appropriate entries for the `shasums_url`, `shasums_signature_url`, `shasum` and each binary must be satisfactorily digitally signed. The required properties are documented in the [Response Properties](https://www.terraform.io/docs/internals/provider-registry-protocol.html#response-properties-1) section.

It is important to note that these are relative paths to the same provider endpoint. The payload maps directly to the `download_url`, `shasums_signature_url ` and `shasums_url` in the corresponding reference in the provider. These files can be shared from any independent location, like a GitHub repo, and can be arbitrarily hosted. In this example, the location is relative to the hosting endpoint.

In our example, we are using the same URL endption and the structure for the download branch is as follows:

```
mirror
├── interrupt-software
│   └── seng
│       └── hashicups
│           └── 0.2.0
│               ├── darwin_amd64
│               │   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS
│               │   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS.sig
│               │   └── terraform-provider-hashicups_0.2.0_darwin_amd64.zip
│               └── linux_amd64
│                   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS
│                   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS.sig
│                   └── terraform-provider-hashicups_0.2.0_linux_amd64.zip
```

### Fillin in the Response Properties

For this example, we generated a testing GPG key to sign our content.

```
gpg --list-keys
/Users/gilberto/.gnupg/pubring.kbx
----------------------------------
pub   rsa4096 2020-12-07 [SC]
      FB844BE5D8887127AC354CC4B271********D72C
uid           [ultimate] G Castillo <gilberto@hashicorp.com>
sub   rsa4096 2020-12-07 [E]
```

##### Generate SHA256SUMS
We generate SHA256 Check Sum for the compressed binary that is distributed.

```
shasum -a 256 terraform-provider-hashicups_0.2.0_darwin_amd64.zip > terraform-provider-hashicups_0.2.0_SHA256SUMS
```
The SHA256SUMS also populates the `shasum` field in the package metadata. The contents of the `SHA256SUMS` should reflect something like this.

```
fc7355d19ba718760f780213ea2fb4310882180423e4f027ed8bbf2e2380d851  terraform-provider-hashicups_0.2.0_darwin_amd64.zip
```
##### Sign the SHA256SUMS
We then use the GPG key to sign the SHA256SUMS file. It is important to share that we might encounter some issues with the key signing. The Terraform Provider might complain about having a bad signature. After a bit of search magic, the work-around that is to use a detached the signature from the original document.

```
gpg --output terraform-provider-hashicups_0.2.0_SHA256SUMS.sig --clear-sign terraform-provider-hashicups_0.2.0_SHA256SUMS
```
Alway verify that the signature is valid:

```
gpg --verify terraform-provider-hashicups_0.2.0_SHA256SUMS.sig
gpg: assuming signed data in 'terraform-provider-hashicups_0.2.0_SHA256SUMS'
gpg: Signature made Mon  7 Dec 10:51:26 2020 EST
gpg:                using RSA key FB844BE5D8887127AC354CC4B271********D72C
gpg: Good signature from "G Castillo <gilberto@hashicorp.com>" [ultimate]
```

### Preparing and Adding a Signing Key

In the documentation, it is infeferred that we need to sumbmit our signing information to registry.terraform.io before using the provider. However, that is not so with a private emulation of the Registry Provider. The information cannot be ommitted from the provider package. See more in the [documentation](https://www.terraform.io/docs/registry/providers/publishing.html#preparing-and-adding-a-signing-key).

```
gpg --armor --export gilberto@hashicorp.com
```

The generated public key should be formatted to fit into the provider package file. For instance, removing the end of line carriage return and replacing it with `\n` characaters instead using a regular expression.

![Screen_Recording_2020-12-07_01.gif] (images/Screen_Recording_2020-12-07_01.gif)

The final hierarchy for the mirror is as follows:

```
mirror
├── interrupt-software
│   └── seng
│       └── hashicups
│           └── 0.2.0
│               ├── darwin_amd64
│               │   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS
│               │   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS.sig
│               │   └── terraform-provider-hashicups_0.2.0_darwin_amd64.zip
│               └── linux_amd64
│                   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS
│                   ├── terraform-provider-hashicups_0.2.0_SHA256SUMS.sig
│                   └── terraform-provider-hashicups_0.2.0_linux_amd64.zip
└── v1
    ├── modules
    └── providers
        └── seng
            └── hashicups
                ├── 0.2.0
                │   └── download
                │       ├── darwin
                │       │   └── amd64
                │       └── linux
                │           └── amd64
                └── versions

15 directories, 9 files

```

### Populating the provider endpoint

In this example, we are borrowing from [Tom Straub's brilliant example](https://github.com/straubt1/terraform-network-mirror/blob/main/aws/main.tf) to populate an S3 bucket and use that endpoint as the entry point for the providers URL. We are making a minor change in the S3 bucket name to reflect our own identity and then pushing the contents [mirror](./mirror) folder.

```
locals {
  aws_region       = "us-west-1"
  s3_bucket_name   = "interrupt-software"
  mirror_directory = "../mirror"

  tags = {
    owner = "gilberto"
    acl   = "public-read"
  }
}

...
```
Once we have all of the assets ready, we can then create our blob using the given code. The end result is an URL to the required assets. In this case the endpoint is [https://interrupt-software.s3.amazonaws.com/](https://interrupt-software.s3.amazonaws.com).

![](images/Screen_Recording_2020-12-07_02.gif)

---
### Testing the provider registry

##### Terraform OSS

The intent is to reference the provider without any localized depencendies. In this case, there is no `.terraformrc` and or environment variables to override the default download location of the provider. The essential reference in the [main.tf](./hashicups-cli/main.tf) is the following block.

```
terraform {
  required_providers {
    hashicups = {
      source  = "interrupt-software.s3.amazonaws.com/seng/hashicups"
      version = "0.2.0"
    }
  }
}
```
Through the initialization of the provider we observe the `init` and `apply` sequences. More importantly, we see the download of the provider into the desired `.terraform` folder.

![](images/Screen_Recording_2020-12-07_03.gif)

---
##### Terraform Cloud

Introducing the same code into a [generic repository](https://github.com/interrupt-software/hashicups), we align the repo against a Terraform Cloud workspace. When triggering a change to the repository, we can observe the generation of work within Terraform Cloud.

![](images/Screen_Recording_2020-12-07_04.gif)

---
In examining the actual workload generated, we find the reference to the URL endpoint that we desire.

![](images/Screen_Recording_2020-12-07_05.gif)

---
In the end, the job is completed as expected.

![](images/Screen_Recording_2020-12-07_06.gif)
