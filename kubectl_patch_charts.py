#!/usr/bin/env python2
import sys, yaml, os, subprocess, json, uuid

with open('charts-config.yaml') as f:
    values = yaml.load(f)

commit_message = sys.argv[1]

# no patches detected
exit_code = 2

if commit_message:
    for chart_name, chart_values in values.items():
        if os.path.exists('charts-external/{}'.format(chart_name)):
            if chart_values.get('automatic-update'):
                auto_update_values = chart_values['automatic-update']
                if auto_update_values['commit-message'] in commit_message:
                    container_name = auto_update_values['container-name']
                    if auto_update_values.get('daemonset-name'):
                        object_type = 'daemonset'
                        object_name = auto_update_values['daemonset-name']
                    else:
                        object_type = 'deployment'
                        object_name = auto_update_values['deployment-name']
                    image_prop = auto_update_values.get('image-prop', 'image')
                    image = subprocess.check_output('./read_env_yaml.sh {} {}'.format(chart_name, image_prop), shell=True)
                    image = json.loads(image)
                    app_name = auto_update_values.get('app-name', container_name)
                    src_dir = 'pipelines'
                    target_dir = 'pipelines'
                    if auto_update_values.get('pipelines-hot-reload'):
                        print('hot reloading {}'.format(chart_name))
                        if '--dry-run' in sys.argv:
                            if os.system('docker pull {}'.format(image)) == 0:
                                print('hot reload dry run successful for {}'.format(chart_name))
                                exit_code = 0
                            else:
                                print('failed hot reload dry run for {}'.format(chart_name))
                                exit_code = 1
                        else:
                            target_uuid = str(uuid.uuid1())
                            pod_name = subprocess.check_output('kubectl get pods -l "app={}"'.format(app_name)
                                                               + " -o 'jsonpath={.items[0].metadata.name}'",
                                                               shell=True)
                            exit_code = 0
                            for cmd in [
                                'docker run -d --name={} --entrypoint sleep {} 86400'.format(chart_name, image),
                                'docker cp {0}:/{1} ./{0}/'.format(chart_name, src_dir),
                                'docker rm --force {}'.format(chart_name),
                                "kubectl exec -c {} {} -- mkdir /{}".format(container_name,
                                                                            pod_name,
                                                                            target_uuid),
                                'kubectl cp ./{} {}:/{}/ -c {}'.format(chart_name,
                                                                       pod_name, target_uuid,
                                                                       container_name),
                                'rm -fr {}'.format(chart_name),
                                "kubectl exec -c {} {} cp -fR /{}/pipelines/'*' /{}/".format(container_name,
                                                                                             pod_name,
                                                                                             target_uuid,
                                                                                             target_dir),
                                "kubectl exec -c {} {} rm -fr /{}".format(container_name,
                                                                          pod_name,
                                                                          target_uuid),
                                "kubectl exec -c {} {} pipenv install --system --deploy --ignore-pipfile".format(container_name,
                                                                                                                 pod_name),
                                "kubectl exec -c {} {} pip install .".format(container_name,
                                                                             pod_name),
                                "kubectl exec -c {} {} /dpp/docker/run.sh stop-server".format(container_name,
                                                                                              pod_name)
                            ]:
                                if os.system(cmd) != 0:
                                    print('failed hot reload ({})'.format(cmd))
                                    exit_code = 1
                                    break
                            if exit_code == 0:
                                print('successfull hot reload {}'.format(chart_name))
                    else:
                        patch_params = '{}/{}'.format(object_type, object_name)
                        patch_params += ' "{}={}"'.format(container_name, image)
                        print('patching {}'.format(patch_params))
                        if '--dry-run' in sys.argv:
                            if os.system('kubectl set image --dry-run -o yaml {}'.format(patch_params)) == 0:
                                print('dry run successful for {}'.format(chart_name))
                                exit_code = 0
                            else:
                                print('failed patch dry run for {}'.format(chart_name))
                                exit_code = 1
                        elif os.system('kubectl set image {}'.format(patch_params)) == 0:
                            print('successfully patched {}'.format(chart_name))
                            exit_code = 0
                        else:
                            print('failed to patch {}'.format(chart_name))
                            exit_code = 1

exit(exit_code)
