import models.ai.com.ops.hops.helm.v1alpha1 as helmv1alpha1
import models.io.upbound.dev.meta.v1alpha1 as metav1alpha1
import models.k8s.apimachinery.pkg.apis.meta.v1 as metav1

# ==============================================================================
# Unit tests for Kiali XRD
#
# Philosophy: Test YOUR API, not the provider's API.
# - render/validate already checks provider schema correctness
# - Tests should verify XRD spec fields produce expected behavior
# ==============================================================================

_items = [
    # ==========================================================================
    # Test 1: Minimal input renders Helm release with name defaulting to XR name
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "minimal-renders-helm-release"
        spec = {
            compositionPath = "apis/kialis/composition.yaml"
            xrdPath = "apis/kialis/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Kiali {
                metadata.name = "test-kiali"
                spec.clusterName = "test-cluster"
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "test-kiali"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 2: Custom labels are applied and merged with defaults
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-labels-merged-with-defaults"
        spec = {
            compositionPath = "apis/kialis/composition.yaml"
            xrdPath = "apis/kialis/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Kiali {
                metadata.name = "labeled-kiali"
                spec = {
                    clusterName = "test-cluster"
                    # labels uses x-kubernetes-preserve-unknown-fields, use untyped
                    labels = {team = "platform", environment = "staging"}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata = {
                        name = "labeled-kiali"
                        labels = {
                            "hops.ops.com.ai/managed" = "true"
                            "hops.ops.com.ai/kiali" = "labeled-kiali"
                            team = "platform"
                            environment = "staging"
                        }
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 3: overrideAllValues replaces defaults
    # Note: overrideAllValues uses x-kubernetes-preserve-unknown-fields
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "override-all-values"
        spec = {
            compositionPath = "apis/kialis/composition.yaml"
            xrdPath = "apis/kialis/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Kiali {
                metadata.name = "override-test"
                spec = {
                    clusterName = "my-cluster"
                    overrideAllValues = {fullnameOverride = "custom-kiali", auth = {strategy = "openid"}}
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "override-test"
                    spec.forProvider.values = {
                        fullnameOverride = "custom-kiali"
                        auth = {strategy = "openid"}
                    }
                }
            ]
        }
    }

    # ==========================================================================
    # Test 4: Custom namespace is applied to Helm release
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-namespace"
        spec = {
            compositionPath = "apis/kialis/composition.yaml"
            xrdPath = "apis/kialis/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Kiali {
                metadata.name = "namespaced-kiali"
                spec = {
                    clusterName = "test-cluster"
                    namespace = "istio-system"
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "namespaced-kiali"
                    spec.forProvider.namespace = "istio-system"
                }
            ]
        }
    }

    # ==========================================================================
    # Test 5: Custom providerConfigRef is applied
    # ==========================================================================
    metav1alpha1.CompositionTest {
        metadata.name = "custom-provider-config"
        spec = {
            compositionPath = "apis/kialis/composition.yaml"
            xrdPath = "apis/kialis/definition.yaml"
            timeoutSeconds = 60
            validate = False
            xr = helmv1alpha1.Kiali {
                metadata.name = "custom-provider"
                spec = {
                    clusterName = "test-cluster"
                    providerConfigRef = {
                        name = "my-helm-provider"
                        kind = "ProviderConfig"
                    }
                }
            }
            assertResources = [
                {
                    apiVersion = "helm.m.crossplane.io/v1beta1"
                    kind = "Release"
                    metadata.name = "custom-provider"
                    spec.providerConfigRef = {
                        name = "my-helm-provider"
                        kind = "ProviderConfig"
                    }
                }
            ]
        }
    }
]

items = _items
