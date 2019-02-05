function set_git_config() {
  git config user.name "$1"
  git config user.email "$2"
}

function replace_if_necessary() {
  package_name=$1
  blobname=$(basename $(ls ../${package_name}/*))
  if ! bosh blobs | grep -q ${blobname}; then
    existing_blob=$(bosh blobs | awk '{print ${package_name}}' | grep "${package_name}" || true)
    if [ -n "${existing_blob}" ]; then
      bosh remove-blob ${existing_blob}
    fi
    bosh add-blob --sha2 ../${package_name}/${blobname} ${blobname}
    bosh upload-blobs
  else
    echo "Blob $blobname already exists. Nothing to do."
  fi
}
